<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Set_US_Commit_Name</fullName>
        <field>Name</field>
        <formula>User_Story__r.Name &amp; &quot; &quot; &amp;  LEFT( Snapshot_Commit__r.Commit_Id__c , 7)</formula>
        <name>Set US Commit Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>Set User Story Commit Name</fullName>
        <actions>
            <name>Set_US_Commit_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>true</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
