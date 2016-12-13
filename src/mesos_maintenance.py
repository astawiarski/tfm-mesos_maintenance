#!/bin/env python
# -*- coding: utf-8 -*-
"""
This script (AWS Lambda) is use to trigger maintenance mode when receive event

"""
from __future__ import print_function
import time
import sys
import logging
import json
import boto3
import requests

EC2_TERMINATING = "autoscaling:EC2_INSTANCE_TERMINATING"
MAINTENANCE_URL = "http://{endpoint}/maintenance/schedule"
logging.basicConfig(stream=sys.stderr, level=logging.INFO)


def lambda_handler(event, dummy_contest):
    """
        main function who is the entry point to the lambda function
    """
    logging.warning(event)
    sns_message = json.loads(event['Records'][0]['Sns']['Message'])

    if sns_message.get("Event", "") == "autoscaling:TEST_NOTIFICATION":
        return "Test Notification: Done!"

    if sns_message["LifecycleTransition"] != EC2_TERMINATING:
        logging.warning(
            "Receive message from Non-Terminating Event:\n %s",
            sns_message
        )
        return

    set_maintenance(
        sns_message['NotificationMetadata'],
        get_ip_dns(sns_message['EC2InstanceId'])
    )

    remove_instance_from_elbs(sns_message['EC2InstanceId'])

    # should notify ASG to complete lifecycle; but we wait for timeout, to make
    # sure mesos does drain all task


def get_ip_dns(instance_id):
    """
        from a given instance return the private ip
    """
    ec2 = boto3.client('ec2')
    dinst = ec2.describe_instances(InstanceIds=[instance_id])
    instance = dinst["Reservations"][0]["Instances"][0]
    if "PrivateIpAddress" not in instance:
        logging.warning(dinst)
    return (instance.get("PrivateIpAddress"), instance.get("PrivateDnsName"))


def set_maintenance(master_endpoint, ip_dns_agent):
    """
    change the desired capacity with the amount change in arguement

    """
    logging.warning(ip_dns_agent)
    if not ip_dns_agent[0]:
        logging.warning("can't set Maintenance mode")
        return

    req_state = requests.get(MAINTENANCE_URL.format(endpoint=master_endpoint))
    if not req_state.ok:
        raise Exception(
            "Failled to get Maintenance Schedule:\n%s" % req_state.text
        )

    maintenance = req_state.json()
    current_win = maintenance.get('windows', [])

    newwin = []
    # clear miantenance
    for window in current_win:
        t_info = window['unavailability']
        time_nano = time.time()*1000000000
        window_start = t_info["start"]["nanoseconds"]
        window_duration = t_info["duration"]["nanoseconds"]
        end_since = time_nano - (window_start + window_duration)
        if end_since < 0:
            newwin.append(window)
        else:
            logging.warning(
                "cleaning %s maintenance ended since %d s",
                window["machine_ids"],
                end_since/1000000000
            )
    # maintenance from now + 20s  for 10minute
    newwin.append({
        "machine_ids": [{"ip": ip_dns_agent[0], "hostname": ip_dns_agent[1]}],
        "unavailability": {
            "start": {
                "nanoseconds": int(time.time()*1000000000 + 20000000000)
            },
            "duration": {"nanoseconds": 600000000000}
        }
    })
    maintenance['windows'] = newwin
    req_state = requests.post(
        MAINTENANCE_URL.format(endpoint=master_endpoint),
        json=maintenance
    )
    logging.warning(req_state)
    if not req_state.ok:
        raise Exception(
            "Failled to Set Maintenance mode to %s:\n%s" % (
                ip_dns_agent, req_state.text
            )
        )
    return


def remove_instance_from_elbs(instance):
    """
    this function will remove instance for all elb is register on
    checking all of them could be an issue (scale)
    """
    try:
        client = boto3.client('elb')
        elbs = client.describe_load_balancers()
        for elb in elbs['LoadBalancerDescriptions']:
            if any(i.get('InstanceId') == instance for i in elb['Instances']):
                logging.warning(
                    "Deregistering from %s",
                    elb["LoadBalancerName"]
                )
                deres = client.deregister_instances_from_load_balancer(
                    LoadBalancerName=elb['LoadBalancerName'],
                    Instances=[{"InstanceId": instance}]
                )
                if deres.get("HTTPStatusCode", 0) != 200:
                    logging.warning(deres)

    except Exception as err:
        logging.error(err)


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("%s <mesos_host> <instance_id>" % sys.argv[0])
    else:
        set_maintenance(sys.argv[1], get_ip_dns(sys.argv[2]))

# FILTERS = [".*payments-web$", ".*-workers-.*"]
