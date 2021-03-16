@isTest
private class TestReleaseExt {
    
    static testMethod void testSuccess() {
        insert TestUtilities.getTestSettings();

        Release__c release = new Release__c(Name = 'Winter Release');
        insert release;

        Test.startTest();
        ReleaseExt ext = new ReleaseExt(new ApexPages.StandardController(release));
        System.assertEquals(release.Id, ext.release.Id);

        // Assert the default version values
        System.assertEquals('1', ext.versionWrapper.major);
        System.assertEquals('1.1', ext.versionWrapper.minor);
        System.assertEquals('1.0.1', ext.versionWrapper.patch);
        System.assertEquals('', ext.versionWrapper.prefix);
        System.assertEquals('', ext.versionWrapper.suffix);
        System.assertEquals('1', ext.versionWrapper.newVersion);

        ext.versionWrapper.newVersion = '13.5.76';
        ext.updateRelease();

        release = [SELECT Id, Version__c FROM Release__C WHERE Id = :release.Id];
        System.assertEquals(ext.versionWrapper.newVersion, release.Version__c);

        Test.stopTest();
    }

    static testMethod void testVersionCalculations() {
        insert TestUtilities.getTestSettings();
        Release__c previousRelease = new Release__c(Name = 'Summer Release', Status__c = 'Released');
        insert previousRelease;
        System.assert(previousRelease.Id != null);

        Release__c release = new Release__c(Name = 'Winter Release');
        Release__c release2 = new Release__c(Name = 'Summer Release', Version__c = 'v7-SUMMER');
        insert new List<Release__c>{ release, release2 };

        Test.startTest();

        // Assert the default version values since the previous version does not have a Version value set
        ReleaseExt ext = new ReleaseExt(new ApexPages.StandardController(release));
        System.assertEquals(release.Id, ext.release.Id);
        System.assertEquals('1', ext.versionWrapper.major);
        System.assertEquals('1.1', ext.versionWrapper.minor);
        System.assertEquals('1.0.1', ext.versionWrapper.patch);
        System.assertEquals('', ext.versionWrapper.prefix);
        System.assertEquals('', ext.versionWrapper.suffix);
        System.assertEquals('1', ext.versionWrapper.newVersion);

        // Add a version to the previous release and assert that extra values are added to a single number version (e.g. 6 + .1 || 6 + .0.1)
        previousRelease.Version__c = '6';
        update previousRelease;
        ReleaseExt ext2 = new ReleaseExt(new ApexPages.StandardController(release));
        System.assertEquals(release.Id, ext2.release.Id);
        System.assertEquals('7', ext2.versionWrapper.major);
        System.assertEquals('6.1', ext2.versionWrapper.minor);
        System.assertEquals('6.0.1', ext2.versionWrapper.patch);
        System.assertEquals('', ext2.versionWrapper.prefix);
        System.assertEquals('', ext2.versionWrapper.suffix);
        System.assertEquals('7', ext2.versionWrapper.newVersion);

        // Assert that prefix and suffix values are added even with special characters
        previousRelease.Version__c = 'v@$%&*)7.7?x565km-Winter';
        update previousRelease;
        ReleaseExt ext4 = new ReleaseExt(new ApexPages.StandardController(release));
        System.assertEquals(release.Id, ext4.release.Id);
        System.assertEquals('8', ext4.versionWrapper.major);
        System.assertEquals('7.8', ext4.versionWrapper.minor);
        System.assertEquals('7.7.1', ext4.versionWrapper.patch);
        System.assertEquals('v@$%&*)', ext4.versionWrapper.prefix);
        System.assertEquals('?x565km-Winter', ext4.versionWrapper.suffix);
        System.assertEquals('v@$%&*)8?x565km-Winter', ext4.versionWrapper.newVersion);

        // Assert that 0 is taken as a valid previousVersion and that the newVersion defaults to the current release Version
        release.Version__c = 'v0.7';
        update release;
        previousRelease.Version__c = 'v0';
        update previousRelease;
        ReleaseExt ext3 = new ReleaseExt(new ApexPages.StandardController(release));
        System.assertEquals(release.Id, ext3.release.Id);
        System.assertEquals('1', ext3.versionWrapper.major);
        System.assertEquals('0.1', ext3.versionWrapper.minor);
        System.assertEquals('0.0.1', ext3.versionWrapper.patch);
        System.assertEquals('v', ext3.versionWrapper.prefix);
        System.assertEquals('', ext3.versionWrapper.suffix);
        System.assertEquals('v0.7', ext3.versionWrapper.newVersion);

        // Assert Lookup Changed in the UI
        ext3.lookupAux.Release__c = release2.Id;
        ext3.getPreviousRelease();
        System.assertEquals('8', ext3.versionWrapper.major);
        System.assertEquals('7.1', ext3.versionWrapper.minor);
        System.assertEquals('7.0.1', ext3.versionWrapper.patch);
        System.assertEquals('v', ext3.versionWrapper.prefix);
        System.assertEquals('-SUMMER', ext3.versionWrapper.suffix);
        System.assertEquals('v0.7', ext3.versionWrapper.newVersion);

        Test.stopTest();
    }

    static testMethod void testEmptySpacesAtVersion() {
        insert TestUtilities.getTestSettings();

        Release__c release = new Release__c(Name = 'Winter Release');
        insert release;

        Test.startTest();
        ReleaseExt ext = new ReleaseExt(new ApexPages.StandardController(release));
        System.assertEquals(release.Id, ext.release.Id);

        // Assert the default version values
        System.assertEquals('1', ext.versionWrapper.major);
        System.assertEquals('1.1', ext.versionWrapper.minor);
        System.assertEquals('1.0.1', ext.versionWrapper.patch);
        System.assertEquals('', ext.versionWrapper.prefix);
        System.assertEquals('', ext.versionWrapper.suffix);
        System.assertEquals('1', ext.versionWrapper.newVersion);

        ext.versionWrapper.newVersion = '13 5 76';
        ext.updateRelease();

        List<Apexpages.Message> messages = ApexPages.getMessages();
        boolean pageHasMessage = false;
        for(Apexpages.Message message : messages){
            if (message.getDetail().contains(Label.Version_Format_Message)) {
                pageHasMessage = true;
            }
        }
        System.assert(pageHasMessage);

        ext.versionWrapper.newVersion = '13.5.76';
        ext.updateRelease();

        release = [SELECT Id, Version__c FROM Release__C WHERE Id = :release.Id];
        System.assertEquals(ext.versionWrapper.newVersion, release.Version__c);

        Test.stopTest();
    }
}