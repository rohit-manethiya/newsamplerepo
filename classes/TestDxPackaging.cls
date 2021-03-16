/**
 * Created by ferhatozsavran on 9/11/18.
 */
@IsTest
private class TestDxPackaging {
    @TestSetup
    static void setupData() {
        TestUtilities.enableLicenses(2, 2, 2, 2, 2);
    }

    //install unlock packages with dependencies
    @IsTest
    static void unlockPackagesWithDependencies() {
        TestUtilities tu = new TestUtilities();

        // Create user to assign as developer to the user stories
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

        TestUtilities.assignLicense(String.valueOf(tu.item('User', 0).get('Username')), true, true, true, true, true);

        System.runAs((User) tu.item('User', 0)) {
            // Create environment record
            tu.insertSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Scratch Org' });

            // Create dev hub org record
            tu.insertSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'Dev Org 1',
                    'Org_Type__c' => 'Dev Org',
                    'SFDC_Org_ID__c' => 'orgIdasd',
                    'Token__c' => 'tokenda',
                    'Username__c' => 'test1@test1.com',
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 0).Id,
                    'is_Developer_Hub_Org__c' => true
                }
            );

            // Create org record
            tu.insertSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'Scratch Org 1',
                    'Org_Type__c' => 'Scratch Org',
                    'SFDC_Org_ID__c' => 'orgId',
                    'Token__c' => 'token',
                    'Username__c' => 'test@test.com',
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 0).Id,
                    'Developer_Hub_Org__c' => tu.item('Org__c', 0).Id
                }
            );

            // Create git repository record
            tu.insertSObject('Git_Repository__c', new Map<String, Object>{ 'Name' => 'git 1', 'URI__c' => 'https://git.com' });

            // Create git snapshot record
            tu.insertSObject(
                'Git_Backup__c',
                new Map<String, Object>{
                    'Name' => 'my first git snapshot',
                    'Branch__c' => 'master',
                    'Frequency__c' => '',
                    'Git_Repository__c' => tu.item('Git_Repository__c', 0).Id,
                    'Last_Backup__c' => Date.today(),
                    'Org__c' => tu.item('Org__c', 1).Id
                }
            );

            Id recordTypeIdArtifact = Schema.SObjectType.Artifact__c.getRecordTypeInfosByName().get('Salesforce Package').getRecordTypeId();

            // Create artifact record
            tu.insertSObject(
                'Artifact__c',
                new Map<String, Object>{
                    'Name' => 'FullTest',
                    'RecordTypeId' => recordTypeIdArtifact,
                    'Description__c' => 'Withing this unlocked salesforce package we will be testing package creation, versioning, promotion and package installation',
                    'Package_Type__c' => 'Unlocked',
                    'Org_Credential__c' => tu.item('Org__c', 1).Id,
                    'Target_Dev_Hub_Org__c' => tu.item('Org__c', 0).Id,
                    'Package_Id__c' => '0Ho1t000000001nCAA',
                    'No_Namespace__c' => true,
                    'Sfdc_Login_Url__c' => 'https://login.salesforce.com',
                    'Source_Api_Version__c' => '43.0',
                    'Artifact_Repository__c' => tu.item('Git_Repository__c', 0).Id
                }
            );

            // Create artifact version record
            tu.insertSObject(
                'Artifact_Version__c',
                new Map<String, Object>{
                    'Name' => 'FullTest - 1.0.0.1',
                    'Artifact__c' => tu.item('Artifact__c', 0).Id,
                    'Version_Description__c' => 'Account operations',
                    'Package_Version_Id__c' => '05i1t0000000043AAA',
                    'Subscriber_Version_Id__c' => '04t1t000001MlMsAAK',
                    'Version_Name__c' => 'Winter 19',
                    'Branch__c' => 'DXFullTestWinter191001',
                    'Tag__c' => 'DX/1.0.0.1',
                    'Version_number__c' => '1.0.0.1'
                }
            );

            // Create artifact record
            tu.insertSObject(
                'Artifact__c',
                new Map<String, Object>{
                    'Name' => 'FullTest1',
                    'RecordTypeId' => recordTypeIdArtifact,
                    'Description__c' => 'Withing this unlocked salesforce package we will be testing package creation, versioning, promotion and package installation',
                    'Package_Type__c' => 'Unlocked',
                    'Org_Credential__c' => tu.item('Org__c', 1).Id,
                    'Target_Dev_Hub_Org__c' => tu.item('Org__c', 0).Id,
                    'Package_Id__c' => '0Ho1t000000001nCAA',
                    'No_Namespace__c' => true,
                    'Sfdc_Login_Url__c' => 'https://login.salesforce.com',
                    'Source_Api_Version__c' => '43.0',
                    'Artifact_Repository__c' => tu.item('Git_Repository__c', 0).Id
                }
            );

            // Create artifact version record
            tu.insertSObject(
                'Artifact_Version__c',
                new Map<String, Object>{
                    'Name' => 'FullTest 1 - 1.0.0.1',
                    'Artifact__c' => tu.item('Artifact__c', 1).Id,
                    'Version_Description__c' => 'Account operations',
                    'Package_Version_Id__c' => '05i1t0000000043AAA',
                    'Subscriber_Version_Id__c' => '04t1t000001MlMsAAK',
                    'Version_Name__c' => 'Winter 19',
                    'Branch__c' => 'DXFullTestWinter191001',
                    'Tag__c' => 'DX/1.0.0.1',
                    'Version_number__c' => '1.0.0.1'
                }
            );

            // Create artifact dependency record
            tu.insertSObject(
                'Artifact_Dependency__c',
                new Map<String, Object>{
                    'Dependent_Artifact__c' => tu.item('Artifact__c', 0).Id,
                    'Depending_Artifact__c' => tu.item('Artifact__c', 1).Id,
                    'Depending_Artifact_Version__c' => tu.item('Artifact_Version__c', 1).Id,
                    'Depends_on_the_latest_version__c' => false
                }
            );

            //Use the PageReference Apex class to instantiate a page
            PageReference pageRef = Page.DXOperation;

            //In this case, the Visualforce page named 'DXOperation' is the starting point of this test method.
            Test.setCurrentPage(pageRef);

            //Instantiate and construct the controller class of DX Operation page.
            DXOperationController controller = new DXOperationController();

            //Select Scratch Org Operations and execute the change function
            controller.selectedOperation = '1';
            //controller.resetDom();

            //Check the map size
            //System.assertEquals(1, controller.objectNameMap.size());

            //Select the Scratch Org 1 from picklist and populate actions
            controller.selectedOrgId = tu.item('Org__c', 1).Id;
            controller.getOperationActions();

            //Select commit history from action and load snapshots commit
            ApexPages.currentPage().getParameters().put('actionName', 'lm');
            controller.enableSelectedPanels();

            //Instantiate and construct the controller class of component.
            ScratchOrgMetadataController somcController = new ScratchOrgMetadataController();
            somcController.setComponentMode('add');
            somcController.setShowTemplateButtons(false);
            somcController.setShowButtons(true);
            somcController.setControllerKey('ScratchOrgMetadata');
            somcController.setPageController(controller);

            //Select artifact and render artifact panels
            ApexPages.currentPage().getParameters().put('typeName', 'unlocked'); //Old value unlockPackage
            somcController.selectType();

            /*somcController.selectedOrgId = tu.item('Org__c', 1).Id;
            somcController.getArtifacts();
            somcController.componentVariables.selectedArtifactId = tu.item('Artifact__c', 0).Id;
            somcController.getArtifactVersions();
            somcController.componentVariables.selectedVersionId = tu.item('Artifact_Version__c', 0).Id;
            somcController.addValuesToSelectedPackages();*/

            //Click to the load metadata button. Set mock callout class
            Test.startTest();
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', '{"example":"test"}', null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            somcController.loadMetadata();

            //run the event listener job for load metadata job
            ApexPages.currentPage().getParameters().put('jobFinished', 'true');
            ApexPages.currentPage().getParameters().put('jobSuccess', 'true');
            ApexPages.currentPage().getParameters().put('jobMessage', '');
            ApexPages.currentPage().getParameters().put('jobType', CopadoNotificationHelper.DX_LOAD_METADATA);
            controller.jobStatusNotification();
            Test.stopTest();
        }
    }

    //install second generation packages
    /*@IsTest static void secondGenerationPackagesWithDependencies() {
        TestUtilities tu = new TestUtilities();

        // Create user to assign as developer to the user stories
        tu.insertSObject('User', new Map<String,Object>{
                'ProfileId' => [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
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
        });

        TestUtilities.assignLicense(String.valueOf(tu.item('User',0).get('Username')), true, true, true, true, true);

        System.runAs((User)tu.item('User',0)) {

            // Create environment record
            tu.insertSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Scratch Org'
            });

            // Create dev hub org record
            tu.insertSObject('Org__c', new Map<String, Object>{
                    'Name' => 'Dev Org 1',
                    'Org_Type__c' => 'Dev Org',
                    'SFDC_Org_ID__c' => 'orgIdasd',
                    'Token__c' => 'tokenda',
                    'Username__c' => 'test1@test1.com',
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 0).Id,
                    'is_Developer_Hub_Org__c' => true
            });

            // Create org record
            tu.insertSObject('Org__c', new Map<String, Object>{
                    'Name' => 'Scratch Org 1',
                    'Org_Type__c' => 'Scratch Org',
                    'SFDC_Org_ID__c' => 'orgId',
                    'Token__c' => 'token',
                    'Username__c' => 'test@test.com',
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 0).Id,
                    'Developer_Hub_Org__c' => tu.item('Org__c', 0).Id
            });

            // Create git repository record
            tu.insertSObject('Git_Repository__c', new Map<String, Object>{
                    'Name' => 'git 1',
                    'URI__c' => 'https://git.com'
            });

            // Create git snapshot record
            tu.insertSObject('Git_Backup__c', new Map<String, Object>{
                    'Name' => 'my first git snapshot',
                    'Branch__c' => 'master',
                    'Frequency__c' => '',
                    'Git_Repository__c' => tu.item('Git_Repository__c', 0).Id,
                    'Last_Backup__c' => Date.today(),
                    'Org__c' => tu.item('Org__c', 1).Id
            });

            Id recordTypeIdArtifact = Schema.SObjectType.Artifact__c.getRecordTypeInfosByName().get('Salesforce Package').getRecordTypeId();

            // Create artifact record
            tu.insertSObject('Artifact__c', new Map<String, Object>{
                    'Name' => 'FullTest',
                    'RecordTypeId' => recordTypeIdArtifact,
                    'Description__c' => 'Withing this unlocked salesforce package we will be testing package creation, versioning, promotion and package installation',
                    'Package_Type__c' => 'Second-Generation Package',
                    'Org_Credential__c' => tu.item('Org__c', 1).Id,
                    'Target_Dev_Hub_Org__c' => tu.item('Org__c', 0).Id,
                    'Package_Id__c' => '0Ho1t000000001nCAA',
                    'No_Namespace__c' => false,
                    'Package_Namespace__c' => 'myfirst2gp',
                    'Sfdc_Login_Url__c' => 'https://login.salesforce.com',
                    'Source_Api_Version__c' => '43.0',
                    'Artifact_Repository__c' => tu.item('Git_Repository__c', 0).Id
            });

            // Create artifact version record
            tu.insertSObject('Artifact_Version__c', new Map<String, Object>{
                    'Name' => 'FullTest - 1.0.0.1',
                    'Artifact__c' => tu.item('Artifact__c', 0).Id,
                    'Version_Description__c' => 'Account operations',
                    'Package_Version_Id__c' => '05i1t0000000043AAA',
                    'Subscriber_Version_Id__c' => '04t1t000001MlMsAAK',
                    'Version_Name__c' => 'Winter 19',
                    'Branch__c' => 'DXFullTestWinter191001',
                    'Tag__c' => 'DX/1.0.0.1',
                    'Version_number__c' => '1.0.0.1'
            });

            //Use the PageReference Apex class to instantiate a page
            PageReference pageRef = Page.DXOperation;

            //In this case, the Visualforce page named 'DXOperation' is the starting point of this test method.
            Test.setCurrentPage(pageRef);

            //Instantiate and construct the controller class of DX Operation page.
            DXOperationController controller = new DXOperationController();

            //Select Scratch Org Operations and execute the change function
            controller.selectedOperation = '1';
            /*controller.resetDom();

            //Check the map size
            System.assertEquals(1, controller.objectNameMap.size());

            //Select the Scratch Org 1 from picklist and populate actions
            controller.selectedOperationDataId = tu.item('Org__c', 1).Id;
            controller.populatePossibleActions();

            //Select commit history from action and load snapshots commit
            ApexPages.currentPage().getParameters().put('actionName', 'lm');
            controller.enableSelectedPanels();

            //Instantiate and construct the controller class of component.
            ScratchOrgMetadataController somcController = new ScratchOrgMetadataController();
            somcController.componentMode = 'add';
            somcController.showTemplateButtons = false;
            somcController.showButtons = true;
            somcController.controllerKey = 'ScratchOrgMetadata';
            somcController.pageController = controller;

            //Select artifact and render artifact panels
            ApexPages.currentPage().getParameters().put('typeName', 'managed'); //Old Value: secondGenerationPackage
            somcController.selectType();

            somcController.selectedOrgId = tu.item('Org__c', 1).Id;
            somcController.getArtifacts();
            somcController.componentVariables.selectedArtifactId = tu.item('Artifact__c', 0).Id;
            somcController.getArtifactVersions();
            somcController.componentVariables.selectedVersionId = tu.item('Artifact_Version__c', 0).Id;
            somcController.addValuesToSelectedPackages();
            ApexPages.currentPage().getParameters().put('aVersion', tu.item('Artifact_Version__c', 0).Id);
            somcController.removePackage();
            somcController.addValuesToSelectedPackages();
            somcController.addValuesToSelectedPackages(); // to cover the validation

            ScratchOrgController socController = new ScratchOrgController();
            socController.componentMode = 'add';
            socController.showTemplateButtons = false;
            socController.showButtons = true;
            socController.pageController = controller;
            socController.controllerKey = 'ScratchOrgTemplate';
            socController.mergeArtifactOrgDefinitionDependencies();


            //Click to the load metadata button. Set mock callout class
            Test.startTest();
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', '{"example":"test"}', null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            somcController.loadMetadata();

            //run the event listener job for load metadata job
            ApexPages.currentPage().getParameters().put('jobFinished', 'true');
            ApexPages.currentPage().getParameters().put('jobSuccess', 'true');
            ApexPages.currentPage().getParameters().put('jobMessage', '');
            ApexPages.currentPage().getParameters().put('jobType', CopadoNotificationHelper.DX_LOAD_METADATA);
            controller.jobStatusNotification();
            Test.stopTest();
        }
    }*/

    //DXPackageAsyncJobHandler
    @IsTest
    static void jobHandlerer() {
        DXPackageAsyncJobHandler controller = new DXPackageAsyncJobHandler();

        //run the event listener job for load metadata job
        ApexPages.currentPage().getParameters().put('jobFinished', 'true');
        ApexPages.currentPage().getParameters().put('jobSuccess', 'true');
        ApexPages.currentPage().getParameters().put('jobMessage', '');
        ApexPages.currentPage().getParameters().put('jobType', CopadoNotificationHelper.DX_CREATE_PACKAGE);
        controller.jobStatusNotification();

        //run the event listener job for load metadata job
        ApexPages.currentPage().getParameters().put('jobFinished', 'true');
        ApexPages.currentPage().getParameters().put('jobSuccess', 'true');
        ApexPages.currentPage().getParameters().put('jobMessage', '');
        ApexPages.currentPage().getParameters().put('jobType', CopadoNotificationHelper.DX_CREATE_PACKAGE_VERSION);
        controller.jobStatusNotification();

        //run the event listener job for load metadata job
        ApexPages.currentPage().getParameters().put('jobFinished', 'true');
        ApexPages.currentPage().getParameters().put('jobSuccess', 'true');
        ApexPages.currentPage().getParameters().put('jobMessage', '');
        ApexPages.currentPage().getParameters().put('jobType', CopadoNotificationHelper.DX_PROMOTE_BETA_RELEASED);
        controller.jobStatusNotification();

        //run the event listener job for load metadata job
        ApexPages.currentPage().getParameters().put('jobFinished', 'true');
        ApexPages.currentPage().getParameters().put('jobSuccess', 'true');
        ApexPages.currentPage().getParameters().put('jobMessage', '');
        ApexPages.currentPage().getParameters().put('jobType', CopadoNotificationHelper.DX_PACKAGE_UPDATE);
        controller.jobStatusNotification();

        //run the event listener job for load metadata job
        ApexPages.currentPage().getParameters().put('jobFinished', 'true');
        ApexPages.currentPage().getParameters().put('jobSuccess', 'true');
        ApexPages.currentPage().getParameters().put('jobMessage', '');
        ApexPages.currentPage().getParameters().put('jobType', CopadoNotificationHelper.DX_PACKAGE_VERSION_UPDATE);
        controller.jobStatusNotification();

        //run the event listener job for load metadata job
        ApexPages.currentPage().getParameters().put('jobFinished', 'true');
        ApexPages.currentPage().getParameters().put('jobSuccess', 'false');
        ApexPages.currentPage().getParameters().put('jobMessage', 'Error var');
        ApexPages.currentPage().getParameters().put('jobType', CopadoNotificationHelper.DX_PACKAGE_VERSION_UPDATE);
        controller.jobStatusNotification();
    }
}