<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Deployment_Completed_email_alert</fullName>
        <description>Deployment Completed email alert</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Copado_Deployer/NewDeploymentResultSummary</template>
    </alerts>
    <fieldUpdates>
        <fullName>Send_deployment_command</fullName>
        <field>Deployment_command_sent__c</field>
        <formula>now()</formula>
        <name>Send deployment command</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>Deployment Completed</fullName>
        <actions>
            <name>Deployment_Completed_email_alert</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Deployment__c.Send_Deployment_Complete_email__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <criteriaItems>
            <field>Deployment__c.Status__c</field>
            <operation>equals</operation>
            <value>Completed Successfully,Completed with Errors,Cancelled</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Deployment Time</fullName>
        <active>false</active>
        <criteriaItems>
            <field>Deployment__c.Status__c</field>
            <operation>equals</operation>
            <value>Scheduled</value>
        </criteriaItems>
        <criteriaItems>
            <field>Deployment__c.Schedule__c</field>
            <operation>equals</operation>
            <value>Deploy later</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <tasks>
        <fullName>Deployment_scheduled</fullName>
        <assignedToType>owner</assignedToType>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <offsetFromField>Deployment__c.Date__c</offsetFromField>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>Deployment scheduled</subject>
    </tasks>
</Workflow>
