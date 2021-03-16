@IsTest
public with sharing class TestLightningReadyFieldsController {
	@IsTest
	static void testController() {
		Contact c = new Contact();

		LightningReadyFieldsController handler = new LightningReadyFieldsController();
		System.assertEquals('', handler.objectName);
		System.assertEquals(null, handler.getFieldDescribe());
		System.assertEquals(null, handler.getSobjectField());

		handler.subjectedObject = c;
		handler.fName = 'LastName';
		
		System.assertEquals('Contact', handler.objectName);
		System.assertEquals(Contact.LastName.getDescribe().getName(), handler.getFieldDescribe().getName());
		System.assertEquals(Contact.LastName, handler.getSobjectField());
		System.assertEquals(false, handler.isReadOnlyField);
		System.assertEquals(true,handler.isRequiredField);

		System.assertEquals(true, handler.isInputField);
		System.assertEquals(false, handler.isTextareaField);
		System.assertEquals(false, handler.isPicklistField);
		System.assertEquals(false, handler.isDependentPicklistField);
		System.assertEquals(false, handler.isMultiPicklistField);
		System.assertEquals(false, handler.isCheckboxField);
		System.assertEquals(false, handler.isDatetimeField);
		System.assertEquals(false, handler.isLookupField);

		handler.fName = 'AccountId';
		System.assertEquals(true, handler.isLookupField);

		handler.fName = 'Description';
		System.assertEquals(false, handler.isInputField);
		System.assertEquals(true, handler.isTextareaField);

		handler.fName = 'Salutation';
		System.assertEquals(false, handler.isInputField);
		System.assertEquals(true, handler.isPicklistField);

		handler.fName = 'HasOptedOutOfEmail';
		System.assertEquals(false, handler.isInputField);
		System.assertEquals(true, handler.isCheckboxField);

		handler.fName = 'LastCUUpdateDate';
		System.assertEquals(false, handler.isInputField);
		System.assertEquals(true, handler.isDatetimeField);

		c.LastName = 'Test';
		insert c;

		handler.fName = 'LastName';
		System.assertEquals(false, handler.isReadOnlyField);
	}
}