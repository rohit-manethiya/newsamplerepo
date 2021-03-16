@isTest
private class TestMetadataTypesHelper {
	
	@isTest static void test_method_one() {
		Org__c o = new Org__c(name = 'o',Metadata_Types__c='ApexClass,ApexPage');
		insert o;
		List<String> types = new List<String>();
		types.add('ApexClass');
		types.add('ApexPage');
		MetadataTypesHelper.metadataTypes = types;
		MetadataTypesHelper.getMetadataTypesFromOrg(o.id);
		MetadataTypesHelper.getMetadataTypesByOrgId(o.id);

		List<String> ex = new List<String>();
		ex.add('ApexClass');
		System.assertEquals(1,MetadataTypesHelper.getTypeOptionsByOrgId(o.id,ex).size());

		System.assertEquals('ApexPage', MetadataTypesHelper.joinOptions(MetadataTypesHelper.getTypeOptionsByOrgId(o.id,ex)));
	}
	
}