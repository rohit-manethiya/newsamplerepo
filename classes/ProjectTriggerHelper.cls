public without sharing class ProjectTriggerHelper {
public static boolean indexMedadataChangedFlag = false;

	public static void runIndexMetadataJob(){
		database.executebatch(new IndexMetadataJob(),50);
	}

	public static void checkIndexMedadataChanged(Project__c oldProject, Project__c newProject){

		if((oldProject.Index_Metadata__c != newProject.Index_Metadata__c)  && newProject.Index_Metadata__c == true){
			indexMedadataChangedFlag = true;
		}
	}

}