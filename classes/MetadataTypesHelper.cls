/**
 * This class is a helper to manage the metadata types filters in
 * controllers extentions
 */
public  class MetadataTypesHelper {

	public static List<String> metadataTypes;

	/**
	 * Returns a list of metadata selected in org
	 * @orgId String 
	 */
	public static String getMetadataTypesFromOrg(String orgId){
		//avoid on query new orgs
		if(orgId == null){
				return '';
		}
		return [SELECT Metadata_Types__c FROM Org__c WHERE Id=:orgId].Metadata_Types__c;
	}
	
	/**
	 * Returns a list of metadata types for the org requested from Heroku API
	 * @orgId String 
	 */
	public static List<String> getMetadataTypesByOrgId(String orgId){
		//avoid on query new orgs
		if(orgId == null){
				return new List<String>();
		}
		//local cache
        if(MetadataTypesHelper.metadataTypes == null || MetadataTypesHelper.metadataTypes.isEmpty()){
        	MetadataTypesHelper.metadataTypes = DeployAPI.metadataTypes(orgId,UserInfo.getSessionId());
        }

        return MetadataTypesHelper.metadataTypes;
	}

	/**
	 * Returns a metadata types options to be shown in a VF
	 * @param orgId String 
	 * @param exclude  List<String> 
	 */
	public static List<SelectOption> getTypeOptionsByOrgId(String orgId,List<String> exclude){

		List<SelectOption> options = new List<SelectOption>();
        Set<String> tmp = new Set<String>();
        tmp.addAll(exclude);
        for(String t:MetadataTypesHelper.getMetadataTypesByOrgId(orgId)){
            if(!tmp.contains(t)){
           		options.add(new SelectOption(t,t));  
           	}  
        }
        return options;
	}

	/**
	 * Returns a string join by coma of option list, 
	 * @param   
	 */
	public static  String joinOptions(List<SelectOption> options){

		String[] res = new String[]{};

		for(SelectOption so:options){
            res.add( so.getValue() );   
        }

        return String.join(res,',');
	}


	

}