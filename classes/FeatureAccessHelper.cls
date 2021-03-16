/*
	This Helper class is used to declare methods depending on the FLS and OLS that a feature needs to be able to work correctly

 */
public with sharing class FeatureAccessHelper {
	
	public static Boolean isSCAFeatureAccessible() {
		Boolean access = false;
		if(	
			//Fields
			schema.sObjectType.Static_Code_Analysis_Result__c.fields.User_Story__c.isAccessible() &&
		   	schema.sObjectType.Static_Code_Analysis_Result__c.fields.Number_of_Violations__c.isAccessible() &&
		   	schema.sObjectType.Static_Code_Analysis_Result__c.fields.Score_v11__c.isAccessible() &&
			schema.sObjectType.Deployment_Flow_Step__c.fields.Source_Environment__c.isAccessible() &&
			schema.sObjectType.Deployment_Flow_Step__c.fields.Destination_Environment__c.isAccessible() &&			
			schema.sObjectType.Deployment_Flow__c.fields.Static_Code_Analysis_Settings__c.isAccessible() &&
		   	schema.sObjectType.Static_Code_Analysis_Rule__c.fields.Message__c.isAccessible() &&
		   	schema.sObjectType.Environment__c.fields.Current_SCA_Score__c.isAccessible() &&
		   	schema.sObjectType.Environment__c.fields.Maximum_SCA_Score__c.isAccessible() &&
			schema.sObjectType.Static_Code_Analysis_Result__c.fields.Org_Credential__c.isAccessible() &&		   	
			schema.sObjectType.Deployment_Flow_Step__c.fields.Deployment_Flow__c.isAccessible()

		   	){
		   	access = true;
		}
		return access;
	}

	public static Boolean isComplianceScanResultAccessible() {
		Boolean access = false;
		if(	
			//Fields
			schema.sObjectType.Compliance_Scan_Result__c.fields.Org_Credential__c.isAccessible() &&
			schema.sObjectType.Compliance_Scan_Result__c.fields.Git_Snapshot__c.isAccessible() &&
			schema.sObjectType.Compliance_Scan_Result__c.fields.Status__c.isAccessible()
		   	) {
		   	access = true;
		}
		return access;
	}
}