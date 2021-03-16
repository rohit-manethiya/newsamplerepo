@IsTest
private with sharing class AddCCHRuleCriteriaExtTest {
    static TestUtilities tu = new TestUtilities();
    @TestSetup
    static void setupData() {
        tu.insertSObject(
            'User',
            new Map<String, Object>{
                'ProfileId' => [SELECT Id FROM Profile WHERE Name = 'System Administrator']
                .Id,
                'LastName' => 'LastName',
                'Email' => 'test1@test1.com',
                'Username' => 'puser000@amamama.com' + System.currentTimeMillis(),
                'CompanyName' => 'TEST',
                'Title' => 'title',
                'Alias' => 'alias',
                'TimeZoneSidKey' => 'America/Los_Angeles',
                'EmailEncodingKey' => 'UTF-8',
                'LanguageLocaleKey' => 'en_US',
                'LocaleSidKey' => 'en_US'
            }
        );
        TestUtilities.enableLicenses(2, 2, 2, 2, 2);
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Copado_User'];
        insert new PermissionSetAssignment(AssigneeId = tu.item('User', 0).Id, PermissionSetId = ps.Id);
    }

    @IsTest
    static void addCCHRuleCriteria() {
        //TestUtilities tu = new TestUtilities();
        User testUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(testUser.Username), true, true, true, true, true);

        System.runAs(testUser) {
            String namespace = [SELECT COUNT() FROM ApexClass WHERE Name = 'CopadoSetupController' AND NamespacePrefix = 'copado'] == 1
                ? 'copado__'
                : '';

            // Create compliance rule
            Compliance_Rule__c complianceRule = new Compliance_Rule__c();
            complianceRule.Active__c = true;
            complianceRule.Action__c = Schema.getGlobalDescribe()
                    .get(namespace + 'Compliance_Rule__c')
                    .getDescribe()
                    .fields.getMap()
                    .get(namespace + 'Action__c')
                    .getDescribe()
                    .getPicklistValues()[0]
                .getValue();
            complianceRule.Error_Message__c = 'test error message';
            complianceRule.Matching_Criteria__c = 'Equals';
            complianceRule.Record_Count__c = 1;
            complianceRule.Record_Count_Criteria__c = 'Number of groups';
            complianceRule.RecordTypeId = Schema.SObjectType.Compliance_Rule__c.getRecordTypeInfosByName().get('Copado').getRecordTypeId();
            complianceRule.Risk_Details__c = 'test risk details';
            complianceRule.Severity__c = 'Low';

            insert complianceRule;

            System.assertNotEquals(null, complianceRule.Id);

            String responseBody = '[{"categoryType":"Profile","nodes":[{"name":"name","metadataType":"name","metadataNameField":"","fields":["value:string"]},{"name":"applicationVisibilities","metadataType":"applicationVisibility","metadataNameField":"application","fields":["application:string","default:boolean","visible:boolean"]},{"name":"classAccesses","metadataType":"classAccess","metadataNameField":"apexClass","fields":["apexClass:string","enabled:boolean"]},{"name":"customPermissions","metadataType":"customPermission","metadataNameField":"name","fields":["enabled:boolean","name:string"]},{"name":"externalDataSourceAccesses","metadataType":"externalDataSourceAccess","metadataNameField":"externalDataSource","fields":["enabled:boolean","externalDataSource:string"]},{"name":"fieldLevelSecurities","metadataType":"fieldLevelSecurity","metadataNameField":"field","fields":["editable:boolean","field:string","hidden:boolean","readable:boolean"]},{"name":"fieldPermissions","metadataType":"fieldPermission","metadataNameField":"field","fields":["editable:boolean","field:string","hidden:boolean","readable:boolean"]},{"name":"layoutAssignments","metadataType":"layoutAssignment","metadataNameField":"layout","fields":["layout:string","recordType:string"]},{"name":"objectPermissions","metadataType":"objectPermission","metadataNameField":"object","fields":["allowCreate:boolean","allowDelete:boolean","allowEdit:boolean","allowRead:boolean","modifyAllRecords:boolean","object:string","viewAllRecords:boolean"]},{"name":"pageAccesses","metadataType":"pageAccess","metadataNameField":"apexPage","fields":["apexPage:string","enabled:boolean"]},{"name":"profileActionOverrides","metadataType":"profileActionOverride","metadataNameField":"actionName","fields":["actionName:string","content:string","formFactor:string","pageOrSobjectType:string","recordType:string","type:string"]},{"name":"recordTypeVisibilities","metadataType":"recordTypeVisibility","metadataNameField":"recordType","fields":["default:boolean","personAccountDefault:boolean","recordType:string","visible:boolean"]},{"name":"tabVisibilities","metadataType":"TabVisibility","metadataNameField":"tab","fields":["tab:string","visibility:string"]},{"name":"userPermissions","metadataType":"userPermission","metadataNameField":"name","fields":["enabled:boolean","name:string"]}]},{"categoryType":"Certificate","nodes":[{"name":"name","metadataType":"name","metadataNameField":"","fields":["value:string"]},{"name":"Certificate","metadataType":"Certificate","metadataNameField":"masterLabel","fields":["caSigned:boolean","encryptedWithPlatformEncryption:boolean","expirationDate:dateTime","keySize:int","privateKeyExportable:boolean"]}]},{"categoryType":"CustomObject","nodes":[{"name":"name","metadataType":"name","metadataNameField":"","fields":["value:string"]},{"name":"value","metadataType":"valueSetDefinition","metadataNameField":"fullName","fields":["fullName:string","color:string","default:boolean","description:string","isActive:boolean","label:string"]},{"name":"fields","metadataType":"customField","metadataNameField":"fullName","fields":["fullName:string","caseSensitive:boolean","customDataType:string","defaultValue:string","deleteConstraint:string","deprecated:boolean","description:string","displayFormat:string","displayLocationInDecimal:boolean","encrypted:boolean","externalDeveloperName:string","externalId:boolean","fieldManageability:string","formula:string","formulaTreatBlankAs:string","fullName:string","globalPicklist:string","indexed:boolean","inlineHelpText:string","isFilteringDisabled:boolean","isNameField:boolean","isSortingDisabled:boolean","reparentableMasterDetail:boolean","label:string","length:int","maskChar:string","maskType:string","metadataRelationship​ControllingField:string","populateExistingRows:boolean","precision:int","referenceTargetField:string","referenceTo:string","relationshipLabel:string","relationshipName:string","relationshipOrder:int","required:boolean","scale:int","startingNumber:int","stripMarkup:boolean","summarizedField:string","summaryForeignKey:string","summaryOperation:string","trackFeedHistory:boolean","trackHistory:boolean","trackTrending:boolean","trueValueIndexed:boolean","type:string","unique:boolean","visibleLines:int","writeRequiresMasterRead:boolean"]}]},{"categoryType":"CspTrustedSite","nodes":[{"name":"name","metadataType":"name","metadataNameField":"","fields":["value:string"]},{"name":"CspTrustedSite","metadataType":"cspTrustedSite","metadataNameField":"","fields":["description:string","endpointUrl:string","isActive:boolean"]}]},{"categoryType":"NamedCredential","nodes":[{"name":"name","metadataType":"name","metadataNameField":"","fields":["value:string"]},{"name":"NamedCredential","metadataType":"NamedCredential","metadataNameField":"","fields":["fullName:string","allowMergeFieldsInBody:boolean","allowMergeFieldsInHeader:boolean","authProvider:string","certificate:string","endpoint:string","generateAuthorizationHeader:boolean","label:string","oauthRefreshToken:string","oauthScope:string","oauthToken:string","password:string","principalType:string","protocol:string","username:string"]}]},{"categoryType":"Network","nodes":[{"name":"name","metadataType":"name","metadataNameField":"","fields":["value:string"]},{"name":"branding","metadataType":"Branding","metadataNameField":"","fields":["loginFooterText:string","loginLogo:string","pageFooter:string","pageHeader:string","primaryColor:string","primaryComplementColor:string","quaternaryColor:string","quaternaryComplementColor:string","secondaryColor:string","tertiaryColor:string","tertiaryComplementColor:string","zeronaryColor:string","zeronaryComplementColor:string"]},{"name":"networkMemberGroups","metadataType":"NetworkMemberGroup","metadataNameField":"","fields":["permissionSet:string","profile:string"]}]},{"categoryType":"PermissionSet","nodes":[{"name":"name","metadataType":"name","metadataNameField":"","fields":["value:string"]},{"name":"applicationVisibilities","metadataType":"applicationVisibility","metadataNameField":"application","fields":["application:string","visible:boolean"]},{"name":"classAccesses","metadataType":"classAccess","metadataNameField":"apexClass","fields":["apexClass:string","enabled:boolean"]},{"name":"customPermissions","metadataType":"customPermission","metadataNameField":"name","fields":["name:string","enabled:boolean"]},{"name":"externalDataSourceAccesses","metadataType":"externalDataSourceAccess","metadataNameField":"externalDataSource","fields":["externalDataSource:string","enabled:boolean"]},{"name":"fieldPermissions","metadataType":"fieldPermission","metadataNameField":"field","fields":["editable:boolean","field:string","readable:boolean"]},{"name":"objectPermissions","metadataType":"objectPermission","metadataNameField":"object","fields":["allowCreate:boolean","allowDelete:boolean","allowEdit:boolean","allowRead:boolean","modifyAllRecords:boolean","object:string","viewAllRecords:boolean"]},{"name":"tabSettings","metadataType":"tabSetting","metadataNameField":"tab","fields":["tab:string","visibility:string"]},{"name":"pageAccesses","metadataType":"pageAccess","metadataNameField":"apexPage","fields":["apexPage:string","enabled:boolean"]},{"name":"recordTypeVisibilities","metadataType":"recordTypeVisibility","metadataNameField":"recordType","fields":["recordType:string","visible:boolean"]},{"name":"userPermissions","metadataType":"userPermission","metadataNameField":"name","fields":["name:string","enabled:boolean"]}]},{"categoryType":"SamlSsoConfig","nodes":[{"name":"name","metadataType":"name","metadataNameField":"","fields":["value:string"]},{"name":"SamlSsoConfig","metadataType":"SamlSsoConfig","metadataNameField":"name","fields":["fullName:string","attributeName:string","attributeNameIdFormat:string","decryptionCertificate:string","errorUrl:string","executionUserId:string","identityLocation:string","identityMapping:string","issuer:string","loginUrl:string","logoutUrl:string","name:string","oauthTokenEndpoint:string","redirectBinding:boolean","requestSignatureMethod:string","salesforceLoginUrl:string","samlEntityId:string","samlJitHandlerId:string","samlVersion:string","userProvisioning:boolean","validationCert:string"]}]},{"categoryType":"Settings","nodes":[{"name":"name","metadataType":"name","metadataNameField":"","fields":["value:string"]},{"name":"dispositions","metadataType":"FileUploadAndDownloadSettings","metadataNameField":"fileType","fields":["behavior:string","filetype:string","securityRiskFileType:boolean"]},{"name":"ipRanges","metadataType":"IpRange","metadataNameField":"","fields":["description:string","start:string","end:string"]},{"name":"passwordPolicies","metadataType":"passswordPolicy","metadataNameField":"","fields":["apiOnlyUserHomePageURL:string","complexity:string","expiration:string","minimumPasswordLifetime:boolean","historyRestriction:string","lockoutInterval:string","maxLoginAttempts:string","minimumPasswordLength:string","obscureSecretAnswer:boolean","passwordAssistanceMessage:string","passwordAssistanceURL:string","questionRestriction:string"]},{"name":"sessionSettings","metadataType":"sessionSettings","metadataNameField":"","fields":["disableTimeoutWarning:boolean","enableCSPOnEmail:boolean","enableCSRFOnGet:boolean","enableCSRFOnPost:boolean","enableCacheAndAutocomplete:boolean","enableClickjackNonsetupSFDC:boolean","enableClickjackNonsetupUser:boolean","enableClickjackNonsetupUserHeaderless:boolean","enableClickjackSetup:boolean","enablePostForSessions:boolean","enableSMSIdentity:boolean","enforceIpRangesEveryRequest:boolean","forceLogoutOnSessionTimeout:boolean","forceRelogin:boolean","hstsOnForcecomSites:boolean","lockSessionsToDomain:boolean","lockSessionsToIp:boolean","logoutURL:boolean","requireHttpOnly:boolean","requireHttps:boolean","sessionTimeout:string"]},{"name":"preferences","metadataType":"OrganizationSettingsDetail","metadataNameField":"","fields":["settingName:string","setttingValue:boolean"]}]}]';
            MockHttpResponseGenerator mockResponse = new MockHttpResponseGenerator(200, 'Complete', responseBody, null);
            Test.setMock(HttpCalloutMock.class, mockResponse);

            Test.startTest();
            ApexPages.StandardController sc = new ApexPages.StandardController(complianceRule);
            AddCCHRuleCriteriaExt handler = new AddCCHRuleCriteriaExt(sc);

            PageReference pageRef = Page.AddCCHRuleCriteria;
            Test.setCurrentPage(pageRef);

            handler.toggleLogic();
            System.assertEquals(3, handler.criteriaList.size());

            handler.removeCriteria();
            System.assertEquals(2, handler.criteriaList.size());

            handler.addNewCriteria();
            System.assertEquals(3, handler.criteriaList.size());

            handler.getNodePicklist();

            complianceRule.Metadata_Type__c = 'Profile';

            handler.getNodePicklist();

            handler.criteriaList[0].nodeName = 'name';
            handler.criteriaList[0].fieldName = 'value';
            pageRef.getParameters().put('cro', '1');
            handler.getFieldOperators();
            System.assertEquals('STRING', handler.criteriaList[0].fieldType);
            System.assertNotEquals(null, handler.criteriaList[0].operatorSet);

            handler.criteriaList[0].operator = 'e';

            handler.criteriaList[1].nodeName = 'applicationVisibility';
            handler.criteriaList[1].fieldName = 'default';
            pageRef.getParameters().put('cro', '2');
            handler.getFieldOperators();
            System.assertEquals('BOOLEAN', handler.criteriaList[1].fieldType);
            System.assertNotEquals(null, handler.criteriaList[1].operatorSet);

            handler.criteriaList[1].operator = '--None--';
            handler.saveCriterias();
            List<Compliance_Rule_Criteria__c> complianceRuleCriteriaList = [
                SELECT Id, Name
                FROM Compliance_Rule_Criteria__c
                WHERE Compliance_Rule__c = :complianceRule.Id
            ];
            System.assertEquals(1, complianceRuleCriteriaList.size());

            String filterCriteriaAND = String.valueOf(complianceRule.Filter_Criteria__c);
            System.assertEquals(false, filterCriteriaAND.contains('AND'));
            pageRef.getParameters().put('cro', '2');
            handler.showFilterLogic = true;
            handler.filterLogic = '1 AND 2 OR 3';

            handler.saveCriterias();
            String filterCriteriaOR = String.valueOf(complianceRule.Filter_criteria__c);
            System.assertEquals(false, filterCriteriaOR.contains('OR'));
            handler.criteriaList[0].nodeName = 'name';
            handler.criteriaList[0].fieldName = 'value';
            pageRef.getParameters().put('cro', '1');
            handler.getFieldOperators();
            handler.criteriaList[0].operator = 'e';
            handler.criteriaList[1].nodeName = 'applicationVisibility';
            handler.criteriaList[1].fieldName = 'default';
            pageRef.getParameters().put('cro', '2');
            handler.getFieldOperators();
            handler.criteriaList[1].operator = 'n';
            handler.criteriaList[2].nodeName = 'applicationVisibility';
            handler.criteriaList[2].fieldName = 'default';
            pageRef.getParameters().put('cro', '3');
            handler.getFieldOperators();
            System.assertEquals('BOOLEAN', handler.criteriaList[1].fieldType);
            System.assertNotEquals(null, handler.criteriaList[1].operatorSet);

            handler.criteriaList[2].operator = 'e';

            handler.filterLogic = '1 AND 2 OR 3';

            handler.saveCriterias();
            String filterCriteriaOR1 = String.valueOf(complianceRule.Filter_Criteria__c);
            System.assertEquals(false, filterCriteriaOR1.contains('OR'));
            handler.filterLogic = '(1 AND 2) OR 3';

            handler.saveCriterias();
            String filterCriteriaOR2 = String.valueOf(complianceRule.Filter_criteria__c);
            System.assertEquals(true, filterCriteriaOR2.contains('OR'));
            System.assertEquals(3, handler.criteriaList.size());

            AddCCHRuleCriteriaExt handler2 = new AddCCHRuleCriteriaExt(sc);
            PageReference pageRef2 = Page.AddCCHRuleCriteria;
            Test.setCurrentPage(pageRef2);
            System.assertEquals(true, handler2.showFilterLogic);
            System.assertEquals('(1 AND 2) OR 3', handler2.filterLogic);
            System.assertNotEquals(0, handler2.legacyCriterias.size());

            handler2.removeCriteria();
            handler2.removeCriteria();
            System.assertEquals(1, handler2.criteriaList.size());
            System.assertEquals(2, handler2.criteriaMemento.size());

            handler2.saveCriterias();
            String filterCriteriaOR3 = String.valueOf(complianceRule.Filter_criteria__c);
            System.assertEquals(true, filterCriteriaOR3.contains('OR'));

            handler2.removeCriteria();
            System.assertEquals(0, handler2.criteriaList.size());
            System.assertEquals(3, handler2.criteriaMemento.size());

            handler2.filterLogic = '1 AND 2';
            handler2.saveCriterias();
            Test.stopTest();
        }
    }

    @IsTest
    static void addCCHRuleCriteriaWithBlankSpacesInValue() {
        User testUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(testUser.Username), true, true, true, true, true);

        System.runAs(testUser) {
            String namespace = [SELECT COUNT() FROM ApexClass WHERE Name = 'CopadoSetupController' AND NamespacePrefix = 'copado'] == 1
                ? 'copado__'
                : '';

            // Create compliance rule
            Compliance_Rule__c complianceRule = new Compliance_Rule__c();
            complianceRule.Active__c = true;
            complianceRule.Action__c = Schema.getGlobalDescribe()
                    .get(namespace + 'Compliance_Rule__c')
                    .getDescribe()
                    .fields.getMap()
                    .get(namespace + 'Action__c')
                    .getDescribe()
                    .getPicklistValues()[0]
                .getValue();
            complianceRule.Error_Message__c = 'test error message';
            complianceRule.Matching_Criteria__c = 'Equals';
            complianceRule.Record_Count__c = 1;
            complianceRule.Record_Count_Criteria__c = 'Number of groups';
            complianceRule.RecordTypeId = Schema.SObjectType.Compliance_Rule__c.getRecordTypeInfosByName().get('Copado').getRecordTypeId();
            complianceRule.Risk_Details__c = 'test risk details';
            complianceRule.Severity__c = 'Low';

            insert complianceRule;

            System.assertNotEquals(null, complianceRule.Id);

            String responseBody = '[{"categoryType":"Profile","nodes":[{"name":"name","metadataType":"name","metadataNameField":"","fields":["value:string"]},{"name":"applicationVisibilities","metadataType":"applicationVisibility","metadataNameField":"application","fields":["application:string","default:boolean","visible:boolean"]},{"name":"classAccesses","metadataType":"classAccess","metadataNameField":"apexClass","fields":["apexClass:string","enabled:boolean"]},{"name":"customPermissions","metadataType":"customPermission","metadataNameField":"name","fields":["enabled:boolean","name:string"]},{"name":"externalDataSourceAccesses","metadataType":"externalDataSourceAccess","metadataNameField":"externalDataSource","fields":["enabled:boolean","externalDataSource:string"]},{"name":"fieldLevelSecurities","metadataType":"fieldLevelSecurity","metadataNameField":"field","fields":["editable:boolean","field:string","hidden:boolean","readable:boolean"]},{"name":"fieldPermissions","metadataType":"fieldPermission","metadataNameField":"field","fields":["editable:boolean","field:string","hidden:boolean","readable:boolean"]},{"name":"layoutAssignments","metadataType":"layoutAssignment","metadataNameField":"layout","fields":["layout:string","recordType:string"]},{"name":"objectPermissions","metadataType":"objectPermission","metadataNameField":"object","fields":["allowCreate:boolean","allowDelete:boolean","allowEdit:boolean","allowRead:boolean","modifyAllRecords:boolean","object:string","viewAllRecords:boolean"]},{"name":"pageAccesses","metadataType":"pageAccess","metadataNameField":"apexPage","fields":["apexPage:string","enabled:boolean"]},{"name":"profileActionOverrides","metadataType":"profileActionOverride","metadataNameField":"actionName","fields":["actionName:string","content:string","formFactor:string","pageOrSobjectType:string","recordType:string","type:string"]},{"name":"recordTypeVisibilities","metadataType":"recordTypeVisibility","metadataNameField":"recordType","fields":["default:boolean","personAccountDefault:boolean","recordType:string","visible:boolean"]},{"name":"tabVisibilities","metadataType":"TabVisibility","metadataNameField":"tab","fields":["tab:string","visibility:string"]},{"name":"userPermissions","metadataType":"userPermission","metadataNameField":"name","fields":["enabled:boolean","name:string"]}]},{"categoryType":"Certificate","nodes":[{"name":"name","metadataType":"name","metadataNameField":"","fields":["value:string"]},{"name":"Certificate","metadataType":"Certificate","metadataNameField":"masterLabel","fields":["caSigned:boolean","encryptedWithPlatformEncryption:boolean","expirationDate:dateTime","keySize:int","privateKeyExportable:boolean"]}]},{"categoryType":"CustomObject","nodes":[{"name":"name","metadataType":"name","metadataNameField":"","fields":["value:string"]},{"name":"value","metadataType":"valueSetDefinition","metadataNameField":"fullName","fields":["fullName:string","color:string","default:boolean","description:string","isActive:boolean","label:string"]},{"name":"fields","metadataType":"customField","metadataNameField":"fullName","fields":["fullName:string","caseSensitive:boolean","customDataType:string","defaultValue:string","deleteConstraint:string","deprecated:boolean","description:string","displayFormat:string","displayLocationInDecimal:boolean","encrypted:boolean","externalDeveloperName:string","externalId:boolean","fieldManageability:string","formula:string","formulaTreatBlankAs:string","fullName:string","globalPicklist:string","indexed:boolean","inlineHelpText:string","isFilteringDisabled:boolean","isNameField:boolean","isSortingDisabled:boolean","reparentableMasterDetail:boolean","label:string","length:int","maskChar:string","maskType:string","metadataRelationship​ControllingField:string","populateExistingRows:boolean","precision:int","referenceTargetField:string","referenceTo:string","relationshipLabel:string","relationshipName:string","relationshipOrder:int","required:boolean","scale:int","startingNumber:int","stripMarkup:boolean","summarizedField:string","summaryForeignKey:string","summaryOperation:string","trackFeedHistory:boolean","trackHistory:boolean","trackTrending:boolean","trueValueIndexed:boolean","type:string","unique:boolean","visibleLines:int","writeRequiresMasterRead:boolean"]}]},{"categoryType":"CspTrustedSite","nodes":[{"name":"name","metadataType":"name","metadataNameField":"","fields":["value:string"]},{"name":"CspTrustedSite","metadataType":"cspTrustedSite","metadataNameField":"","fields":["description:string","endpointUrl:string","isActive:boolean"]}]},{"categoryType":"NamedCredential","nodes":[{"name":"name","metadataType":"name","metadataNameField":"","fields":["value:string"]},{"name":"NamedCredential","metadataType":"NamedCredential","metadataNameField":"","fields":["fullName:string","allowMergeFieldsInBody:boolean","allowMergeFieldsInHeader:boolean","authProvider:string","certificate:string","endpoint:string","generateAuthorizationHeader:boolean","label:string","oauthRefreshToken:string","oauthScope:string","oauthToken:string","password:string","principalType:string","protocol:string","username:string"]}]},{"categoryType":"Network","nodes":[{"name":"name","metadataType":"name","metadataNameField":"","fields":["value:string"]},{"name":"branding","metadataType":"Branding","metadataNameField":"","fields":["loginFooterText:string","loginLogo:string","pageFooter:string","pageHeader:string","primaryColor:string","primaryComplementColor:string","quaternaryColor:string","quaternaryComplementColor:string","secondaryColor:string","tertiaryColor:string","tertiaryComplementColor:string","zeronaryColor:string","zeronaryComplementColor:string"]},{"name":"networkMemberGroups","metadataType":"NetworkMemberGroup","metadataNameField":"","fields":["permissionSet:string","profile:string"]}]},{"categoryType":"PermissionSet","nodes":[{"name":"name","metadataType":"name","metadataNameField":"","fields":["value:string"]},{"name":"applicationVisibilities","metadataType":"applicationVisibility","metadataNameField":"application","fields":["application:string","visible:boolean"]},{"name":"classAccesses","metadataType":"classAccess","metadataNameField":"apexClass","fields":["apexClass:string","enabled:boolean"]},{"name":"customPermissions","metadataType":"customPermission","metadataNameField":"name","fields":["name:string","enabled:boolean"]},{"name":"externalDataSourceAccesses","metadataType":"externalDataSourceAccess","metadataNameField":"externalDataSource","fields":["externalDataSource:string","enabled:boolean"]},{"name":"fieldPermissions","metadataType":"fieldPermission","metadataNameField":"field","fields":["editable:boolean","field:string","readable:boolean"]},{"name":"objectPermissions","metadataType":"objectPermission","metadataNameField":"object","fields":["allowCreate:boolean","allowDelete:boolean","allowEdit:boolean","allowRead:boolean","modifyAllRecords:boolean","object:string","viewAllRecords:boolean"]},{"name":"tabSettings","metadataType":"tabSetting","metadataNameField":"tab","fields":["tab:string","visibility:string"]},{"name":"pageAccesses","metadataType":"pageAccess","metadataNameField":"apexPage","fields":["apexPage:string","enabled:boolean"]},{"name":"recordTypeVisibilities","metadataType":"recordTypeVisibility","metadataNameField":"recordType","fields":["recordType:string","visible:boolean"]},{"name":"userPermissions","metadataType":"userPermission","metadataNameField":"name","fields":["name:string","enabled:boolean"]}]},{"categoryType":"SamlSsoConfig","nodes":[{"name":"name","metadataType":"name","metadataNameField":"","fields":["value:string"]},{"name":"SamlSsoConfig","metadataType":"SamlSsoConfig","metadataNameField":"name","fields":["fullName:string","attributeName:string","attributeNameIdFormat:string","decryptionCertificate:string","errorUrl:string","executionUserId:string","identityLocation:string","identityMapping:string","issuer:string","loginUrl:string","logoutUrl:string","name:string","oauthTokenEndpoint:string","redirectBinding:boolean","requestSignatureMethod:string","salesforceLoginUrl:string","samlEntityId:string","samlJitHandlerId:string","samlVersion:string","userProvisioning:boolean","validationCert:string"]}]},{"categoryType":"Settings","nodes":[{"name":"name","metadataType":"name","metadataNameField":"","fields":["value:string"]},{"name":"dispositions","metadataType":"FileUploadAndDownloadSettings","metadataNameField":"fileType","fields":["behavior:string","filetype:string","securityRiskFileType:boolean"]},{"name":"ipRanges","metadataType":"IpRange","metadataNameField":"","fields":["description:string","start:string","end:string"]},{"name":"passwordPolicies","metadataType":"passswordPolicy","metadataNameField":"","fields":["apiOnlyUserHomePageURL:string","complexity:string","expiration:string","minimumPasswordLifetime:boolean","historyRestriction:string","lockoutInterval:string","maxLoginAttempts:string","minimumPasswordLength:string","obscureSecretAnswer:boolean","passwordAssistanceMessage:string","passwordAssistanceURL:string","questionRestriction:string"]},{"name":"sessionSettings","metadataType":"sessionSettings","metadataNameField":"","fields":["disableTimeoutWarning:boolean","enableCSPOnEmail:boolean","enableCSRFOnGet:boolean","enableCSRFOnPost:boolean","enableCacheAndAutocomplete:boolean","enableClickjackNonsetupSFDC:boolean","enableClickjackNonsetupUser:boolean","enableClickjackNonsetupUserHeaderless:boolean","enableClickjackSetup:boolean","enablePostForSessions:boolean","enableSMSIdentity:boolean","enforceIpRangesEveryRequest:boolean","forceLogoutOnSessionTimeout:boolean","forceRelogin:boolean","hstsOnForcecomSites:boolean","lockSessionsToDomain:boolean","lockSessionsToIp:boolean","logoutURL:boolean","requireHttpOnly:boolean","requireHttps:boolean","sessionTimeout:string"]},{"name":"preferences","metadataType":"OrganizationSettingsDetail","metadataNameField":"","fields":["settingName:string","setttingValue:boolean"]}]}]';
            MockHttpResponseGenerator mockResponse = new MockHttpResponseGenerator(200, 'Complete', responseBody, null);
            Test.setMock(HttpCalloutMock.class, mockResponse);

            Test.startTest();
            ApexPages.StandardController sc = new ApexPages.StandardController(complianceRule);
            AddCCHRuleCriteriaExt handler = new AddCCHRuleCriteriaExt(sc);

            PageReference pageRef = Page.AddCCHRuleCriteria;
            Test.setCurrentPage(pageRef);

            /*handler.toggleLogic();
            System.assertEquals(3, handler.criteriaList.size());

            handler.removeCriteria();
            System.assertEquals(2, handler.criteriaList.size());

            handler.addNewCriteria();
            System.assertEquals(3, handler.criteriaList.size());

            handler.getNodePicklist();*/

            complianceRule.Metadata_Type__c = 'Profile';
            handler.getNodePicklist();

            handler.criteriaList[0].nodeName = 'name';
            handler.criteriaList[0].fieldName = 'value';
            handler.criteriaList[0].input = '    inputvalue     ';
            pageRef.getParameters().put('cro', '1');
            handler.getFieldOperators();
            System.assertEquals('STRING', handler.criteriaList[0].fieldType);
            System.assertNotEquals(null, handler.criteriaList[0].operatorSet);

            handler.criteriaList[0].operator = 'e';

            handler.saveCriterias();
            List<Compliance_Rule_Criteria__c> complianceRuleCriteriaList = [
                SELECT Id, Node__c, Operator__c, Order__c, Value__c, Field__c, Criteria__c
                FROM Compliance_Rule_Criteria__c
                WHERE Compliance_Rule__c = :complianceRule.Id
            ];
            System.assertEquals(1, complianceRuleCriteriaList.size());
            System.assertEquals('name', complianceRuleCriteriaList[0].Node__c);
            System.assertEquals('value', complianceRuleCriteriaList[0].Field__c);
            System.assertEquals('Equals', complianceRuleCriteriaList[0].Operator__c);
            System.assertEquals(1, complianceRuleCriteriaList[0].Order__c);
            System.assertEquals('inputvalue', complianceRuleCriteriaList[0].Value__c);
            System.assertEquals('name.value<EQUALS>inputvalue', complianceRuleCriteriaList[0].Criteria__c);

            Test.stopTest();
        }
    }

    @IsTest
    static void deleteCCHRuleCriteria() {
        //TestUtilities tu = new TestUtilities();
        User testUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(testUser.Username), true, true, true, true, true);

        System.runAs(testUser) {
            String namespace = [SELECT COUNT() FROM ApexClass WHERE Name = 'CopadoSetupController' AND NamespacePrefix = 'copado'] == 1
                ? 'copado__'
                : '';

            // Create compliance rule
            Compliance_Rule__c complianceRule = new Compliance_Rule__c();
            complianceRule.Active__c = true;
            complianceRule.Action__c = Schema.getGlobalDescribe()
                    .get(namespace + 'Compliance_Rule__c')
                    .getDescribe()
                    .fields.getMap()
                    .get(namespace + 'Action__c')
                    .getDescribe()
                    .getPicklistValues()[0]
                .getValue();
            complianceRule.Error_Message__c = 'test error message';
            complianceRule.Matching_Criteria__c = 'Equals';
            complianceRule.Record_Count__c = 1;
            complianceRule.Record_Count_Criteria__c = 'Number of groups';
            complianceRule.RecordTypeId = Schema.SObjectType.Compliance_Rule__c.getRecordTypeInfosByName().get('Copado').getRecordTypeId();
            complianceRule.Risk_Details__c = 'test risk details';
            complianceRule.Severity__c = 'Low';

            insert complianceRule;

            System.assertNotEquals(null, complianceRule.Id);

            String responseBody = '[{"categoryType":"Profile","nodes":[{"name":"name","metadataType":"name","metadataNameField":"","fields":["value:string"]},{"name":"applicationVisibilities","metadataType":"applicationVisibility","metadataNameField":"application","fields":["application:string","default:boolean","visible:boolean"]},{"name":"classAccesses","metadataType":"classAccess","metadataNameField":"apexClass","fields":["apexClass:string","enabled:boolean"]},{"name":"customPermissions","metadataType":"customPermission","metadataNameField":"name","fields":["enabled:boolean","name:string"]},{"name":"externalDataSourceAccesses","metadataType":"externalDataSourceAccess","metadataNameField":"externalDataSource","fields":["enabled:boolean","externalDataSource:string"]},{"name":"fieldLevelSecurities","metadataType":"fieldLevelSecurity","metadataNameField":"field","fields":["editable:boolean","field:string","hidden:boolean","readable:boolean"]},{"name":"fieldPermissions","metadataType":"fieldPermission","metadataNameField":"field","fields":["editable:boolean","field:string","hidden:boolean","readable:boolean"]},{"name":"layoutAssignments","metadataType":"layoutAssignment","metadataNameField":"layout","fields":["layout:string","recordType:string"]},{"name":"objectPermissions","metadataType":"objectPermission","metadataNameField":"object","fields":["allowCreate:boolean","allowDelete:boolean","allowEdit:boolean","allowRead:boolean","modifyAllRecords:boolean","object:string","viewAllRecords:boolean"]},{"name":"pageAccesses","metadataType":"pageAccess","metadataNameField":"apexPage","fields":["apexPage:string","enabled:boolean"]},{"name":"profileActionOverrides","metadataType":"profileActionOverride","metadataNameField":"actionName","fields":["actionName:string","content:string","formFactor:string","pageOrSobjectType:string","recordType:string","type:string"]},{"name":"recordTypeVisibilities","metadataType":"recordTypeVisibility","metadataNameField":"recordType","fields":["default:boolean","personAccountDefault:boolean","recordType:string","visible:boolean"]},{"name":"tabVisibilities","metadataType":"TabVisibility","metadataNameField":"tab","fields":["tab:string","visibility:string"]},{"name":"userPermissions","metadataType":"userPermission","metadataNameField":"name","fields":["enabled:boolean","name:string"]}]},{"categoryType":"Certificate","nodes":[{"name":"name","metadataType":"name","metadataNameField":"","fields":["value:string"]},{"name":"Certificate","metadataType":"Certificate","metadataNameField":"masterLabel","fields":["caSigned:boolean","encryptedWithPlatformEncryption:boolean","expirationDate:dateTime","keySize:int","privateKeyExportable:boolean"]}]},{"categoryType":"CustomObject","nodes":[{"name":"name","metadataType":"name","metadataNameField":"","fields":["value:string"]},{"name":"value","metadataType":"valueSetDefinition","metadataNameField":"fullName","fields":["fullName:string","color:string","default:boolean","description:string","isActive:boolean","label:string"]},{"name":"fields","metadataType":"customField","metadataNameField":"fullName","fields":["fullName:string","caseSensitive:boolean","customDataType:string","defaultValue:string","deleteConstraint:string","deprecated:boolean","description:string","displayFormat:string","displayLocationInDecimal:boolean","encrypted:boolean","externalDeveloperName:string","externalId:boolean","fieldManageability:string","formula:string","formulaTreatBlankAs:string","fullName:string","globalPicklist:string","indexed:boolean","inlineHelpText:string","isFilteringDisabled:boolean","isNameField:boolean","isSortingDisabled:boolean","reparentableMasterDetail:boolean","label:string","length:int","maskChar:string","maskType:string","metadataRelationship​ControllingField:string","populateExistingRows:boolean","precision:int","referenceTargetField:string","referenceTo:string","relationshipLabel:string","relationshipName:string","relationshipOrder:int","required:boolean","scale:int","startingNumber:int","stripMarkup:boolean","summarizedField:string","summaryForeignKey:string","summaryOperation:string","trackFeedHistory:boolean","trackHistory:boolean","trackTrending:boolean","trueValueIndexed:boolean","type:string","unique:boolean","visibleLines:int","writeRequiresMasterRead:boolean"]}]},{"categoryType":"CspTrustedSite","nodes":[{"name":"name","metadataType":"name","metadataNameField":"","fields":["value:string"]},{"name":"CspTrustedSite","metadataType":"cspTrustedSite","metadataNameField":"","fields":["description:string","endpointUrl:string","isActive:boolean"]}]},{"categoryType":"NamedCredential","nodes":[{"name":"name","metadataType":"name","metadataNameField":"","fields":["value:string"]},{"name":"NamedCredential","metadataType":"NamedCredential","metadataNameField":"","fields":["fullName:string","allowMergeFieldsInBody:boolean","allowMergeFieldsInHeader:boolean","authProvider:string","certificate:string","endpoint:string","generateAuthorizationHeader:boolean","label:string","oauthRefreshToken:string","oauthScope:string","oauthToken:string","password:string","principalType:string","protocol:string","username:string"]}]},{"categoryType":"Network","nodes":[{"name":"name","metadataType":"name","metadataNameField":"","fields":["value:string"]},{"name":"branding","metadataType":"Branding","metadataNameField":"","fields":["loginFooterText:string","loginLogo:string","pageFooter:string","pageHeader:string","primaryColor:string","primaryComplementColor:string","quaternaryColor:string","quaternaryComplementColor:string","secondaryColor:string","tertiaryColor:string","tertiaryComplementColor:string","zeronaryColor:string","zeronaryComplementColor:string"]},{"name":"networkMemberGroups","metadataType":"NetworkMemberGroup","metadataNameField":"","fields":["permissionSet:string","profile:string"]}]},{"categoryType":"PermissionSet","nodes":[{"name":"name","metadataType":"name","metadataNameField":"","fields":["value:string"]},{"name":"applicationVisibilities","metadataType":"applicationVisibility","metadataNameField":"application","fields":["application:string","visible:boolean"]},{"name":"classAccesses","metadataType":"classAccess","metadataNameField":"apexClass","fields":["apexClass:string","enabled:boolean"]},{"name":"customPermissions","metadataType":"customPermission","metadataNameField":"name","fields":["name:string","enabled:boolean"]},{"name":"externalDataSourceAccesses","metadataType":"externalDataSourceAccess","metadataNameField":"externalDataSource","fields":["externalDataSource:string","enabled:boolean"]},{"name":"fieldPermissions","metadataType":"fieldPermission","metadataNameField":"field","fields":["editable:boolean","field:string","readable:boolean"]},{"name":"objectPermissions","metadataType":"objectPermission","metadataNameField":"object","fields":["allowCreate:boolean","allowDelete:boolean","allowEdit:boolean","allowRead:boolean","modifyAllRecords:boolean","object:string","viewAllRecords:boolean"]},{"name":"tabSettings","metadataType":"tabSetting","metadataNameField":"tab","fields":["tab:string","visibility:string"]},{"name":"pageAccesses","metadataType":"pageAccess","metadataNameField":"apexPage","fields":["apexPage:string","enabled:boolean"]},{"name":"recordTypeVisibilities","metadataType":"recordTypeVisibility","metadataNameField":"recordType","fields":["recordType:string","visible:boolean"]},{"name":"userPermissions","metadataType":"userPermission","metadataNameField":"name","fields":["name:string","enabled:boolean"]}]},{"categoryType":"SamlSsoConfig","nodes":[{"name":"name","metadataType":"name","metadataNameField":"","fields":["value:string"]},{"name":"SamlSsoConfig","metadataType":"SamlSsoConfig","metadataNameField":"name","fields":["fullName:string","attributeName:string","attributeNameIdFormat:string","decryptionCertificate:string","errorUrl:string","executionUserId:string","identityLocation:string","identityMapping:string","issuer:string","loginUrl:string","logoutUrl:string","name:string","oauthTokenEndpoint:string","redirectBinding:boolean","requestSignatureMethod:string","salesforceLoginUrl:string","samlEntityId:string","samlJitHandlerId:string","samlVersion:string","userProvisioning:boolean","validationCert:string"]}]},{"categoryType":"Settings","nodes":[{"name":"name","metadataType":"name","metadataNameField":"","fields":["value:string"]},{"name":"dispositions","metadataType":"FileUploadAndDownloadSettings","metadataNameField":"fileType","fields":["behavior:string","filetype:string","securityRiskFileType:boolean"]},{"name":"ipRanges","metadataType":"IpRange","metadataNameField":"","fields":["description:string","start:string","end:string"]},{"name":"passwordPolicies","metadataType":"passswordPolicy","metadataNameField":"","fields":["apiOnlyUserHomePageURL:string","complexity:string","expiration:string","minimumPasswordLifetime:boolean","historyRestriction:string","lockoutInterval:string","maxLoginAttempts:string","minimumPasswordLength:string","obscureSecretAnswer:boolean","passwordAssistanceMessage:string","passwordAssistanceURL:string","questionRestriction:string"]},{"name":"sessionSettings","metadataType":"sessionSettings","metadataNameField":"","fields":["disableTimeoutWarning:boolean","enableCSPOnEmail:boolean","enableCSRFOnGet:boolean","enableCSRFOnPost:boolean","enableCacheAndAutocomplete:boolean","enableClickjackNonsetupSFDC:boolean","enableClickjackNonsetupUser:boolean","enableClickjackNonsetupUserHeaderless:boolean","enableClickjackSetup:boolean","enablePostForSessions:boolean","enableSMSIdentity:boolean","enforceIpRangesEveryRequest:boolean","forceLogoutOnSessionTimeout:boolean","forceRelogin:boolean","hstsOnForcecomSites:boolean","lockSessionsToDomain:boolean","lockSessionsToIp:boolean","logoutURL:boolean","requireHttpOnly:boolean","requireHttps:boolean","sessionTimeout:string"]},{"name":"preferences","metadataType":"OrganizationSettingsDetail","metadataNameField":"","fields":["settingName:string","setttingValue:boolean"]}]}]';
            MockHttpResponseGenerator mockResponse = new MockHttpResponseGenerator(200, 'Complete', responseBody, null);
            Test.setMock(HttpCalloutMock.class, mockResponse);

            Test.startTest();
            ApexPages.StandardController sc = new ApexPages.StandardController(complianceRule);
            AddCCHRuleCriteriaExt handler = new AddCCHRuleCriteriaExt(sc);

            PageReference pageRef = Page.AddCCHRuleCriteria;
            Test.setCurrentPage(pageRef);

            handler.toggleLogic();
            System.assertEquals(3, handler.criteriaList.size());

            handler.removeCriteria();
            System.assertEquals(2, handler.criteriaList.size());

            handler.addNewCriteria();
            System.assertEquals(3, handler.criteriaList.size());

            handler.getNodePicklist();

            complianceRule.Metadata_Type__c = 'Profile';

            handler.getNodePicklist();

            handler.criteriaList[0].nodeName = 'name';
            handler.criteriaList[0].fieldName = 'value';
            pageRef.getParameters().put('cro', '1');
            handler.getFieldOperators();
            System.assertEquals('STRING', handler.criteriaList[0].fieldType);
            System.assertNotEquals(null, handler.criteriaList[0].operatorSet);

            handler.criteriaList[0].operator = 'e';

            handler.criteriaList[1].nodeName = 'applicationVisibility';
            handler.criteriaList[1].fieldName = 'default';
            pageRef.getParameters().put('cro', '2');
            handler.getFieldOperators();
            System.assertEquals('BOOLEAN', handler.criteriaList[1].fieldType);
            System.assertNotEquals(null, handler.criteriaList[1].operatorSet);

            handler.criteriaList[1].operator = '--None--';
            handler.saveCriterias();
            List<Compliance_Rule_Criteria__c> complianceRuleCriteriaList = [
                SELECT Id, Name
                FROM Compliance_Rule_Criteria__c
                WHERE Compliance_Rule__c = :complianceRule.Id
            ];
            System.assertEquals(1, complianceRuleCriteriaList.size());
            delete complianceRuleCriteriaList;
            complianceRuleCriteriaList = [SELECT Id, Name FROM Compliance_Rule_Criteria__c WHERE Compliance_Rule__c = :complianceRule.Id];
            System.assertEquals(0, complianceRuleCriteriaList.size());
            Test.stopTest();
        }
    }

    @IsTest
    static void testSuccessfulCriteriaValidation() {
        User testUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(testUser.Username), true, true, true, true, true);

        System.runAs(testUser) {
            String namespace = [SELECT COUNT() FROM ApexClass WHERE Name = 'CopadoSetupController' AND NamespacePrefix = 'copado'] == 1
                ? 'copado__'
                : '';

            // Create compliance rule
            tu.insertSObject(
                'Compliance_Rule__c',
                new Map<String, Object>{
                    'Active__c' => true,
                    'Action__c' => Schema.getGlobalDescribe()
                            .get(namespace + 'Compliance_Rule__c')
                            .getDescribe()
                            .fields.getMap()
                            .get(namespace + 'Action__c')
                            .getDescribe()
                            .getPicklistValues()[0]
                        .getValue(),
                    'Error_Message__c' => 'test error message',
                    'Matching_Criteria__c' => 'Equals',
                    'Record_Count__c' => 1,
                    'Record_Count_Criteria__c' => 'Number of groups',
                    'RecordTypeId' => Schema.SObjectType.Compliance_Rule__c.getRecordTypeInfosByName().get('Copado').getRecordTypeId(),
                    'Risk_Details__c' => 'test risk details',
                    'Severity__c' => 'Low'
                }
            );

            String successBody = '{"ok":"compliance rule successfully validated!!"}';
            MockHttpResponseGenerator mockResponse = new MockHttpResponseGenerator(200, 'Complete', successBody, null);
            Test.setMock(HttpCalloutMock.class, mockResponse);

            Test.startTest();
            ApexPages.StandardController sc = new ApexPages.StandardController(tu.item('Compliance_Rule__c', 0));
            AddCCHRuleCriteriaExt handler = new AddCCHRuleCriteriaExt(sc);
            PageReference pageRef = Page.AddCCHRuleCriteria;
            Test.setCurrentPage(pageRef);
            handler.rule = (Compliance_Rule__c) tu.item('Compliance_Rule__c', 0);
            handler.validateRuleFromPage();

            Test.stopTest();

            System.assertEquals(true, handler.isValid);
        }
    }

    @IsTest
    static void testErrorCriteriaValidation() {
        User testUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(testUser.Username), true, true, true, true, true);

        System.runAs(testUser) {
            String namespace = [SELECT COUNT() FROM ApexClass WHERE Name = 'CopadoSetupController' AND NamespacePrefix = 'copado'] == 1
                ? 'copado__'
                : '';

            // Create compliance rule
            tu.insertSObject(
                'Compliance_Rule__c',
                new Map<String, Object>{
                    'Active__c' => true,
                    'Action__c' => Schema.getGlobalDescribe()
                            .get(namespace + 'Compliance_Rule__c')
                            .getDescribe()
                            .fields.getMap()
                            .get(namespace + 'Action__c')
                            .getDescribe()
                            .getPicklistValues()[0]
                        .getValue(),
                    'Error_Message__c' => 'test error message',
                    'Matching_Criteria__c' => 'Equals',
                    'Record_Count__c' => 1,
                    'Record_Count_Criteria__c' => 'Number of groups',
                    'RecordTypeId' => Schema.SObjectType.Compliance_Rule__c.getRecordTypeInfosByName().get('Copado').getRecordTypeId(),
                    'Risk_Details__c' => 'test risk details',
                    'Severity__c' => 'Low'
                }
            );

            String errorBody = '{"error":"Test Error Message"}';
            MockHttpResponseGenerator mockResponse = new MockHttpResponseGenerator(400, 'Complete', errorBody, null);
            Test.setMock(HttpCalloutMock.class, mockResponse);

            Test.startTest();
            ApexPages.StandardController sc = new ApexPages.StandardController(tu.item('Compliance_Rule__c', 0));
            AddCCHRuleCriteriaExt handler = new AddCCHRuleCriteriaExt(sc);
            PageReference pageRef = Page.AddCCHRuleCriteria;
            Test.setCurrentPage(pageRef);
            handler.rule = (Compliance_Rule__c) tu.item('Compliance_Rule__c', 0);
            handler.validateRuleFromPage();

            Test.stopTest();

            System.assertEquals(false, handler.isValid);
        }
    }

    @IsTest
    static void testExceptionCriteriaValidation() {
        User testUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(testUser.Username), true, true, true, true, true);

        System.runAs(testUser) {
            String namespace = [SELECT COUNT() FROM ApexClass WHERE Name = 'CopadoSetupController' AND NamespacePrefix = 'copado'] == 1
                ? 'copado__'
                : '';

            // Create compliance rule
            tu.insertSObject(
                'Compliance_Rule__c',
                new Map<String, Object>{
                    'Active__c' => true,
                    'Action__c' => Schema.getGlobalDescribe()
                            .get(namespace + 'Compliance_Rule__c')
                            .getDescribe()
                            .fields.getMap()
                            .get(namespace + 'Action__c')
                            .getDescribe()
                            .getPicklistValues()[0]
                        .getValue(),
                    'Error_Message__c' => 'test error message',
                    'Matching_Criteria__c' => 'Equals',
                    'Record_Count__c' => 1,
                    'Record_Count_Criteria__c' => 'Number of groups',
                    'RecordTypeId' => Schema.SObjectType.Compliance_Rule__c.getRecordTypeInfosByName().get('Copado').getRecordTypeId(),
                    'Risk_Details__c' => 'test risk details',
                    'Severity__c' => 'Low'
                }
            );

            String exceptionBody = '<html><head></head><body>SOMETHING WENT TERRIBLY WRONG</body></html>';
            MockHttpResponseGenerator mockResponse = new MockHttpResponseGenerator(500, 'Complete', exceptionBody, null);
            Test.setMock(HttpCalloutMock.class, mockResponse);

            Test.startTest();
            ApexPages.StandardController sc = new ApexPages.StandardController(tu.item('Compliance_Rule__c', 0));
            AddCCHRuleCriteriaExt handler = new AddCCHRuleCriteriaExt(sc);
            PageReference pageRef = Page.AddCCHRuleCriteria;
            Test.setCurrentPage(pageRef);
            handler.rule = (Compliance_Rule__c) tu.item('Compliance_Rule__c', 0);
            handler.validateRuleFromPage();

            Test.stopTest();

            System.assertEquals(null, handler.isValid);
            System.assertEquals(1, ApexPages.getMessages().size());
            System.assert(ApexPages.getMessages()[0].getDetail().contains(Label.Connection_Problem));
        }
    }
}