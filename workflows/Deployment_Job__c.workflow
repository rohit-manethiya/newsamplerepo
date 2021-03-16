<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Set_DJ_Status_to_Failed</fullName>
        <field>Status__c</field>
        <literalValue>Failed</literalValue>
        <name>Set DJ Status to Failed</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_DJ_Status_to_Success</fullName>
        <field>Status__c</field>
        <literalValue>Success</literalValue>
        <name>Set DJ Status to Success</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>Mark Early Job Completion as Failed</fullName>
        <actions>
            <name>Set_DJ_Status_to_Failed</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Deployment_Job__c.Status__c</field>
            <operation>equals</operation>
            <value>In progress</value>
        </criteriaItems>
        <criteriaItems>
            <field>Deployment_Job__c.Early_Completion_Status__c</field>
            <operation>equals</operation>
            <value>Failed</value>
        </criteriaItems>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Mark Early Job Completion as Success</fullName>
        <actions>
            <name>Set_DJ_Status_to_Success</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Deployment_Job__c.Status__c</field>
            <operation>equals</operation>
            <value>In progress</value>
        </criteriaItems>
        <criteriaItems>
            <field>Deployment_Job__c.Early_Completion_Status__c</field>
            <operation>equals</operation>
            <value>Success</value>
        </criteriaItems>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
