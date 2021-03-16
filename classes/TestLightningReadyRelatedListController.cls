@isTest
private class TestLightningReadyRelatedListController {
    
    @testSetup static void methodName() {
		Settings__c s = new Settings__c(
			Namespace__c = 'none',
			CCM_Licenses__c = 50,
			Copado_Licenses__c = 50,
			CST_Licenses__c = 50,
			Server_URL__c = 'https://dev-app-api.copado.com'
		);
		insert s;
    }
    

	@isTest static void test_method_one() {
		Account acc = new Account(Name = 'test acc');
		Utilities.Secure_DML(acc, Utilities.DML_Action.INS, schema.Sobjecttype.Account);

		List<Contact> contactList = new List<Contact>();
		for(Integer i = 0 ; i < 20 ; i++){
			contactList.add(new Contact(LastName = 'test', AccountId = acc.Id));
		}
		Utilities.Secure_DML(contactList, Utilities.DML_Action.INS, schema.Sobjecttype.Contact);

		LightningReadyRelatedListController handler = new LightningReadyRelatedListController();

		handler.objectList = contactList;
		handler.initialSize = 10;
		handler.relName = 'Contacts';
		handler.parentAPI = 'Account';
		List<sObject> datas = handler.dataList;
		handler.getdataset();

		List<Schema.FieldSetMember> fs = handler.fieldSet;
		System.assertEquals(null, fs);

		String objectName = handler.objectName;
		System.assertEquals('Contact', objectName);

		String objectPrefix = handler.objectPrefix;
		System.assertEquals('003', objectPrefix);

		String objectLabel = handler.objectLabel;
		System.assertEquals('Contact', objectLabel);
	}

	@isTest static void test_method_two() {
		LightningReadyRelatedListController handler = new LightningReadyRelatedListController();
		List<Schema.FieldSetMember> fs = handler.fieldSet;
		System.assertEquals(null, fs);

		String objectApi = handler.objectAPI;
		String parentAPI = handler.parentAPI;
		String relName = handler.relName;
		String pId = handler.pId;

		String objectName = handler.objectName;
		System.assertEquals('', objectName);

		String objectPrefix = handler.objectPrefix;
		System.assertEquals('', objectPrefix);

		String objectLabel = handler.objectLabel;
		System.assertEquals('', objectLabel);

        String namespace = handler.getNameSpace();
        System.assertEquals(namespace, Settings.ns);
	}

	@isTest static void test_method_three() {
		Account acc = new Account(Name = 'test acc');
		Utilities.Secure_DML(acc, Utilities.DML_Action.INS, schema.Sobjecttype.Account);

		List<Contact> contactList = new List<Contact>();
		for(Integer i = 0 ; i < 20 ; i++){
			contactList.add(new Contact(LastName = 'test', AccountId = acc.Id));
		}
		Utilities.Secure_DML(contactList, Utilities.DML_Action.INS, schema.Sobjecttype.Contact);

		LightningReadyRelatedListController handler = new LightningReadyRelatedListController();

		handler.initialSize = 10;
		String objectApi = 'Contact';
		String parentAPI = 'Account';
		String relName = 'Contacts';
		String pId = acc.Id;

		handler.objectAPI = objectApi;
		handler.parentAPI = parentAPI;
		handler.relName = relName;
        handler.pId = pId;

		System.assertEquals('Contact', handler.objectApi);
		System.assertEquals('Account', handler.parentAPI);
		System.assertEquals('Contacts', handler.relName);

		List<sObject> dataList = new List<sObject>();
		
		dataList.addAll(handler.getdataset());
		//System.assertNotEquals(0, handler.dataList.size()); // TODO: dataList assertion should be checked.

		dataList.addAll(handler.dataList);

		String viewAll = handler.getViewAllURL();
    }

    @isTest static void test_method_four() {
		Account acc = new Account(Name = 'test acc');
		Utilities.Secure_DML(acc, Utilities.DML_Action.INS, schema.Sobjecttype.Account);

		List<Contact> contactList = new List<Contact>();
		for(Integer i = 0 ; i < 20 ; i++){
			contactList.add(new Contact(LastName = 'test', AccountId = acc.Id));
		}
		Utilities.Secure_DML(contactList, Utilities.DML_Action.INS, schema.Sobjecttype.Contact);

		LightningReadyRelatedListController handler = new LightningReadyRelatedListController();

		handler.objectList = contactList;
		handler.initialSize = 10;
		handler.relName = 'Contacts';
		handler.parentAPI = 'Account';
		List<sObject> datas = handler.dataList;
        handler.getdataset();
        handler.fSetName = 'Contact_Fields';
        
        List<Schema.FieldSetMember> fs = handler.fieldSet;
		System.assertEquals(null, fs);

		String objectName = handler.objectName;
		System.assertEquals('Contact', objectName);

		String objectPrefix = handler.objectPrefix;
		System.assertEquals('003', objectPrefix);

		String objectLabel = handler.objectLabel;
		System.assertEquals('Contact', objectLabel);
	}
}