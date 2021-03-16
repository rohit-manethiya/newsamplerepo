@IsTest
private class TestScratchOrgSettings {
    @TestSetup static void setup() {
        // Create common test records
        insert TestUtilities.getTestSettings();
        TestUtilities.insertUser('user1-dxOperations@test-copado.org', 'System Administrator');
        TestUtilities.assignLicense(UserInfo.getUserName(), true, true, true, true, true);
        TestUtilities.createAllDXTestData();
    }
    static testMethod void testOrgSettingsClassesStructure() {
        System.debug('no debug');
    }
    /*
    static testMethod void testOrgSettingsClassesStructure(){
        ScratchOrgSettings sOrgSettings = new ScratchOrgSettings();
        sOrgSettings.toString();

        ScratchOrgSettings.AccountSettings accSettings = new ScratchOrgSettings.AccountSettings();
        accSettings.getSetting();
        accSettings.showViewHierarchyLink = true;
        accSettings.enableAccountTeams = true;
        accSettings.enableAccountOwnerReport = true;

        ScratchOrgSettings.ActivitiesSettings activitySettings = new ScratchOrgSettings.ActivitiesSettings();
        activitySettings.autoRelateEventAttendees = true;
        activitySettings.enableActivityReminders = true;
        activitySettings.enableClickCreateEvents = true;
        activitySettings.enableDragAndDropScheduling = true;
        activitySettings.enableEmailTracking = true;
        activitySettings.enableGroupTasks = true;
        activitySettings.enableListViewScheduling = true;
        activitySettings.enableMultidayEvents = true;
        activitySettings.enableRecurringEvents = true;
        activitySettings.enableRecurringTasks = true;
        activitySettings.enableSidebarCalendarShortcut = true;
        activitySettings.enableSimpleTaskCreateUI = true;
        activitySettings.enableUNSTaskDelegatedToNotifications = true;
        activitySettings.meetingRequestsLogo = 'Logo';
        activitySettings.showCustomLogoMeetingRequests = true;
        activitySettings.showEventDetailsMultiUserCalendar = true;
        activitySettings.showHomePageHoverLinksForEvents = true;
        activitySettings.showMyTasksHoverLinks = true;

        activitySettings.getSetting();


        ScratchOrgSettings.State stateSetting = new ScratchOrgSettings.State();
        stateSetting.active = true;
        stateSetting.integrationValue = '';
        stateSetting.isoCode = 'EU';
        stateSetting.label = 'label';
        stateSetting.standard = true;
        stateSetting.visible = true;

        ScratchOrgSettings.Country countrySetting = new ScratchOrgSettings.Country();
        countrySetting.visible = true;
        countrySetting.standard = true;
        countrySetting.label = 'label';
        countrySetting.isoCode = 'EU';
        countrySetting.integrationValue = '';
        countrySetting.active = true;
        countrySetting.orgDefault = true;
        countrySetting.states = new List<ScratchOrgSettings.State>{stateSetting};

        ScratchOrgSettings.AddressSettings addresSetting = new ScratchOrgSettings.AddressSettings();
        addresSetting.countries = new List<ScratchOrgSettings.Country>{countrySetting};
        addresSetting.getSetting();

        ScratchOrgSettings.Holidays holidaySetting = new ScratchOrgSettings.Holidays();
        holidaySetting.activityDate = '';
        holidaySetting.businessHours = '';
        holidaySetting.description = '';
        holidaySetting.activityDate = '';
        holidaySetting.endTime = '';
        holidaySetting.isRecurring = '';
        holidaySetting.name = '';
        holidaySetting.recurrenceDayOfMonth = '';
        holidaySetting.recurrenceDayOfWeek = '';
        holidaySetting.recurrenceEndDate = '';
        holidaySetting.recurrenceInstance = '';
        holidaySetting.recurrenceInterval = '';
        holidaySetting.recurrenceMonthOfYear = '';
        holidaySetting.recurrenceStartDate = '';
        holidaySetting.recurrenceType = '';
        holidaySetting.startTime = '';

        ScratchOrgSettings.BusinessHoursEntry businesshoursentrySetting = new ScratchOrgSettings.BusinessHoursEntry();
        businesshoursentrySetting.name = '';
        businesshoursentrySetting.active = '';
        businesshoursentrySetting.bheDefault = '';
        businesshoursentrySetting.fridayEndTime = '';
        businesshoursentrySetting.fridayStartTime = '';
        businesshoursentrySetting.mondayEndTime = '';
        businesshoursentrySetting.saturdayEndTime = '';
        businesshoursentrySetting.mondayStartTime = '';
        businesshoursentrySetting.saturdayStartTime = '';
        businesshoursentrySetting.sundayEndTime = '';
        businesshoursentrySetting.sundayStartTime = '';
        businesshoursentrySetting.thursdayEndTime = '';
        businesshoursentrySetting.thursdayStartTime = '';
        businesshoursentrySetting.timeZoneId = '';
        businesshoursentrySetting.tuesdayEndTime = '';
        businesshoursentrySetting.tuesdayStartTime = '';
        businesshoursentrySetting.wednesdayEndTime = '';
        businesshoursentrySetting.wednesdayStartTime = '';

        ScratchOrgSettings.BusinessHoursSettings businesshourSetting = new ScratchOrgSettings.BusinessHoursSettings();
        businesshourSetting.businessHours = new List<ScratchOrgSettings.BusinessHoursEntry>{businesshoursentrySetting};
        businesshourSetting.holidays = new List<ScratchOrgSettings.Holidays>{holidaySetting};

        businesshourSetting.getSetting();



        ScratchOrgSettings.WebToCaseSettings webtocaseSetting = new ScratchOrgSettings.WebToCaseSettings();
        webtocaseSetting.caseOrigin = '';
        webtocaseSetting.defaultResponseTemplate = '';
        webtocaseSetting.enableWebToCase = true;

        ScratchOrgSettings.EmailToCaseRoutingAddress  emailtocaseroutingaddress = new ScratchOrgSettings.EmailToCaseRoutingAddress();
        emailtocaseroutingaddress.addressType = ScratchOrgSettings.EmailToCaseRoutingAddressType.EmailToCase;
        emailtocaseroutingaddress.authorizedSenders = '';
        emailtocaseroutingaddress.caseOrigin = '';
        emailtocaseroutingaddress.caseOwner = '';
        emailtocaseroutingaddress.caseOwnerType = '';
        emailtocaseroutingaddress.casePriority = '';
        emailtocaseroutingaddress.createTask = true;
        emailtocaseroutingaddress.emailAddress = '';
        emailtocaseroutingaddress.emailServicesAddress = '';
        emailtocaseroutingaddress.isVerified = true;
        emailtocaseroutingaddress.routingName = '';
        emailtocaseroutingaddress.saveEmailHeaders = true;
        emailtocaseroutingaddress.taskStatus = '';

        ScratchOrgSettings.EmailToCaseSettings emailtocaseSetting = new ScratchOrgSettings.EmailToCaseSettings();
        emailtocaseSetting.enableEmailToCase = true;
        emailtocaseSetting.enableHtmlEmail = true;
        emailtocaseSetting.enableOnDemandEmailToCase = true;
        emailtocaseSetting.enableThreadIDInBody = true;
        emailtocaseSetting.enableThreadIDInSubject = true;
        emailtocaseSetting.notifyOwnerOnNewCaseEmail = true;
        emailtocaseSetting.overEmailLimitAction = ScratchOrgSettings.EmailToCaseOnFailureActionType.Bounce;
        emailtocaseSetting.preQuoteSignature = true;
        emailtocaseSetting.routingAddresses = new List<ScratchOrgSettings.EmailToCaseRoutingAddress>{emailtocaseroutingaddress};
        emailtocaseSetting.unauthorizedSenderAction = ScratchOrgSettings.EmailToCaseOnFailureActionType.Bounce;

        ScratchOrgSettings.FeedItemSettings  feeditemSetting = new ScratchOrgSettings.FeedItemSettings();
        feeditemSetting.characterLimit = 1;
        feeditemSetting.collapseThread = true;
        feeditemSetting.displayFormat = ScratchOrgSettings.FeedItemDisplayFormat.displayFDefault;
        feeditemSetting.feedItemType = ScratchOrgSettings.FeedItemType.EmailMessageEvent;

        ScratchOrgSettings.CaseSettings caseSetting = new ScratchOrgSettings.CaseSettings();
        caseSetting.caseAssignNotificationTemplate = 'folderName/emailTemplateName';
        caseSetting.caseCloseNotificationTemplate = 'folderName/emailTemplateName';
        caseSetting.caseCommentNotificationTemplate = 'folderName/emailTemplateName';
        caseSetting.caseCreateNotificationTemplate = 'folderName/emailTemplateName';
        caseSetting.caseFeedItemSettings = new List<ScratchOrgSettings.FeedItemSettings>{feeditemSetting};
        caseSetting.closeCaseThroughStatusChange = true;
        caseSetting.defaultCaseOwner  = '';
        caseSetting.defaultCaseOwnerType  = '';
        caseSetting.defaultCaseUser  = '';
        caseSetting.emailToCase = emailtocaseSetting;
        caseSetting.enableCaseFeed = true;
        caseSetting.enableDraftEmails = true;
        caseSetting.enableEarlyEscalationRuleTriggers = true;
        caseSetting.enableE2CSourceTracking = true;
        caseSetting.enableNewEmailDefaultTemplate = true;
        caseSetting.enableSuggestedArticlesApplication = true;
        caseSetting.enableSuggestedArticlesCustomerPortal = true;
        caseSetting.enableSuggestedArticlesPartnerPortal = true;
        caseSetting.enableSuggestedSolutions = true;
        caseSetting.keepRecordTypeOnAssignmentRule = true;
        caseSetting.newEmailDefaultTemplateClass = '';
        caseSetting.notifyContactOnCaseComment = true;
        caseSetting.notifyDefaultCaseOwner = true;
        caseSetting.notifyOwnerOnCaseComment = true;
        caseSetting.notifyOwnerOnCaseOwnerChange = true;
        caseSetting.showEmailAttachmentsInCaseAttachmentsRL = true;
        caseSetting.showFewerCloseActions = true;
        caseSetting.systemUserEmail = '';
        caseSetting.useSystemEmailAddress = true;
        caseSetting.useSystemUserAsDefaultCaseUser = true;
        caseSetting.webToCase = webtocaseSetting;

        caseSetting.getSetting();

        ScratchOrgSettings.ChatterAnswersSettings chatteranswerSetting = new ScratchOrgSettings.ChatterAnswersSettings();
        chatteranswerSetting.emailFollowersOnBestAnswer = true;
        chatteranswerSetting.emailFollowersOnReply = true;
        chatteranswerSetting.emailOwnerOnPrivateReply = true;
        chatteranswerSetting.emailOwnerOnReply = true;
        chatteranswerSetting.enableAnswerViaEmail = true;
        chatteranswerSetting.enableChatterAnswers = true;
        chatteranswerSetting.enableFacebookSSO = true;
        chatteranswerSetting.enableInlinePublisher = true;
        chatteranswerSetting.enableReputation = true;
        chatteranswerSetting.enableRichTextEditor = true;
        chatteranswerSetting.facebookAuthProvider = '';
        chatteranswerSetting.showInPortals = true;

        chatteranswerSetting.getSetting();

        ScratchOrgSettings.FiscalYearSetting fiscalyearSetting = new ScratchOrgSettings.FiscalYearSetting();
        fiscalyearSetting.fiscalYearNameBasedOn = 'endingMonth';
        fiscalyearSetting.startMonth = '1';


        ScratchOrgSettings.CompanySettings companySetting = new ScratchOrgSettings.CompanySettings();
        companySetting.fiscalYear = fiscalyearSetting;

        companySetting.getSetting();

        ScratchOrgSettings.ContractSettings contractSetting = new ScratchOrgSettings.ContractSettings();
        contractSetting.autoCalculateEndDate = true;
        contractSetting.notifyOwnersOnContractExpiration = true;

        contractSetting.getSetting();

        ScratchOrgSettings.EntitlementSettings entitlementSetting = new ScratchOrgSettings.EntitlementSettings();
        entitlementSetting.assetLookupLimitedToActiveEntitlementsOnAccount = true;
        entitlementSetting.assetLookupLimitedToActiveEntitlementsOnContact = true;
        entitlementSetting.assetLookupLimitedToSameAccount = true;
        entitlementSetting.assetLookupLimitedToSameContact = true;
        entitlementSetting.enableEntitlements = true;
        entitlementSetting.enableEntitlementVersioning = true;
        entitlementSetting.entitlementLookupLimitedToActiveStatus = true;
        entitlementSetting.entitlementLookupLimitedToSameAccount = true;
        entitlementSetting.entitlementLookupLimitedToSameAsset = true;
        entitlementSetting.entitlementLookupLimitedToSameContact = true;

        entitlementSetting.getSetting();

        ScratchOrgSettings.FieldServiceSettings fieldserviceSetting = new ScratchOrgSettings.FieldServiceSettings();
        fieldserviceSetting.fieldServiceNotificationsOrgPref = true;
        fieldserviceSetting.fieldServiceOrgPref = true;
        fieldserviceSetting.serviceAppointmentsDueDateOffsetOrgValue = 1;
        fieldserviceSetting.workOrderLineItemSearchFields = '';
        fieldserviceSetting.workOrderSearchFields = '';

        fieldserviceSetting.getSetting();


        ScratchOrgSettings.FileTypeDispositionAssignmentBean filetypedispositionSetting = new ScratchOrgSettings.FileTypeDispositionAssignmentBean();
        filetypedispositionSetting.behavior = ScratchOrgSettings.FileDownloadBehavior.DOWNLOAD;
        filetypedispositionSetting.filetype = ScratchOrgSettings.FileType.AVI;

        ScratchOrgSettings.FileUploadAndDownloadSecuritySettings fileupoadandownloadSetting = new ScratchOrgSettings.FileUploadAndDownloadSecuritySettings();
        fileupoadandownloadSetting.dispositions = new List<ScratchOrgSettings.FileTypeDispositionAssignmentBean>{filetypedispositionSetting};
        fileupoadandownloadSetting.noHtmlUploadAsAttachment = true;

        fileupoadandownloadSetting.getSetting();



        ScratchOrgSettings.QuotasSettings quotaSetting = new ScratchOrgSettings.QuotasSettings();
        quotaSetting.showQuotas = true;

        ScratchOrgSettings.OpportunityListFieldsUnselectedSettings opplistfieldunselectedSetting = new ScratchOrgSettings.OpportunityListFieldsUnselectedSettings();
        opplistfieldunselectedSetting.field = '';

        ScratchOrgSettings.OpportunityListFieldsSelectedSettings opplistfieldselectedSetting = new ScratchOrgSettings.OpportunityListFieldsSelectedSettings();
        opplistfieldselectedSetting.field = '';

        ScratchOrgSettings.ForecastRangeSettings forecastingrangeSetting = new ScratchOrgSettings.ForecastRangeSettings();
        forecastingrangeSetting.beginning = 1;
        forecastingrangeSetting.displaying = 12;
        forecastingrangeSetting.periodTypes = ScratchOrgSettings.PeriodTypes.Month;

        ScratchOrgSettings.AdjustmentsSettings adjustmentSetting = new ScratchOrgSettings.AdjustmentsSettings();
        adjustmentSetting.enableAdjustments = true;
        adjustmentSetting.enableOwnerAdjustments = true;

        ScratchOrgSettings.ForecastingTypeSettings forecastingtypeSetting = new ScratchOrgSettings.ForecastingTypeSettings();
        forecastingtypeSetting.active = true;
        forecastingtypeSetting.adjustmentsSettings = adjustmentSetting;
        forecastingtypeSetting.forecastedCategoryApiNames = 'commitonly';
        forecastingtypeSetting.forecastingDateType = ScratchOrgSettings.ForecastingDateType.OpportunityCloseDate;
        forecastingtypeSetting.forecastRangeSettings = forecastingrangeSetting;
        forecastingtypeSetting.hasProductFamily = true;
        forecastingtypeSetting.name = '';
        forecastingtypeSetting.opportunityListFieldsSelectedSettings = opplistfieldselectedSetting;
        forecastingtypeSetting.opportunityListFieldsUnselectedSettings = opplistfieldunselectedSetting;
        forecastingtypeSetting.opportunitySplitName = '';
        forecastingtypeSetting.quotasSettings = quotaSetting;
        forecastingtypeSetting.territory2ModelName = '';

        ScratchOrgSettings.ForecastingDisplayedFamilySettings forecastingdisplayfamilySetting = new ScratchOrgSettings.ForecastingDisplayedFamilySettings();
        forecastingdisplayfamilySetting.productFamily = '';

        ScratchOrgSettings.WeightedSourceCategories weightsourcesSetting = new ScratchOrgSettings.WeightedSourceCategories();
        weightsourcesSetting.sourceCategoryApiName = 'commit';
        weightsourcesSetting.weight = 1.0;

        ScratchOrgSettings.ForecastingCategoryMappings forecastingcatmappingSetting = new ScratchOrgSettings.ForecastingCategoryMappings();
        forecastingcatmappingSetting.forecastingItemCategoryApiName = 'openpipeline';
        forecastingcatmappingSetting.weightedSourceCategories = new List<ScratchOrgSettings.WeightedSourceCategories>{weightsourcesSetting};

        ScratchOrgSettings.ForecastingSettings forecastingSetting = new ScratchOrgSettings.ForecastingSettings();
        forecastingSetting.displayCurrency = ScratchOrgSettings.DisplayCurrency.Corporate;
        forecastingSetting.enableForecasts = true;
        forecastingSetting.forecastingCategoryMappings = new List<ScratchOrgSettings.ForecastingCategoryMappings>{forecastingcatmappingSetting};
        forecastingSetting.forecastingDisplayedFamilySettings = new List<ScratchOrgSettings.ForecastingDisplayedFamilySettings>{forecastingdisplayfamilySetting};
        forecastingSetting.forecastingTypeSettings = new List<ScratchOrgSettings.ForecastingTypeSettings>{forecastingtypeSetting};

        forecastingSetting.getSetting();


        ScratchOrgSettings.IdeasSettings ideaSetting = new ScratchOrgSettings.IdeasSettings();
        ideaSetting.enableIdeaThemes = true;
        ideaSetting.enableIdeas = true;
        ideaSetting.enableIdeasReputation = true;
        ideaSetting.enableChatterProfile = false;
        ideaSetting.ideasProfilePage = '';
        ideaSetting.halfLife = 1.0;

        ideaSetting.getSetting();


        ScratchOrgSettings.IoTSettings iotSetting = new ScratchOrgSettings.IoTSettings();
        iotSetting.enableIoT = true;
        iotSetting.iotInsights = true;

        iotSetting.getSetting();



        ScratchOrgSettings.KnowledgeWorkOrderLineItemField knowledgeworkorderlineitemfieldSeting = new ScratchOrgSettings.KnowledgeWorkOrderLineItemField();
        knowledgeworkorderlineitemfieldSeting.name = '';

        ScratchOrgSettings.KnowledgeWorkOrderLineItemFieldsSettings knowledgeworkorderlineitemfieldlistSetting = new ScratchOrgSettings.KnowledgeWorkOrderLineItemFieldsSettings();
        knowledgeworkorderlineitemfieldlistSetting.field = new List<ScratchOrgSettings.KnowledgeWorkOrderLineItemField>{knowledgeworkorderlineitemfieldSeting};

        ScratchOrgSettings.KnowledgeWorkOrderField nowledgeworkorderfieldSetting = new ScratchOrgSettings.KnowledgeWorkOrderField();
        nowledgeworkorderfieldSetting.name = '';

        ScratchOrgSettings.KnowledgeWorkOrderFieldsSettings nowledgeworkorderfieldlistSetting = new ScratchOrgSettings.KnowledgeWorkOrderFieldsSettings();
        nowledgeworkorderfieldlistSetting.field = new List<ScratchOrgSettings.KnowledgeWorkOrderField>{nowledgeworkorderfieldSetting};

        ScratchOrgSettings.KnowledgeCaseField knowledgefasefieldSetting = new ScratchOrgSettings.KnowledgeCaseField();
        knowledgefasefieldSetting.name = new List<String>();

        ScratchOrgSettings.KnowledgeCaseFieldsSettings knowledgecasefieldlistSetting = new ScratchOrgSettings.KnowledgeCaseFieldsSettings();
        knowledgecasefieldlistSetting.field = new List<ScratchOrgSettings.KnowledgeCaseField>{knowledgefasefieldSetting};

        ScratchOrgSettings.KnowledgeSuggestedArticlesSettings knowledgesuggestedarticleSetting = new ScratchOrgSettings.KnowledgeSuggestedArticlesSettings();
        knowledgesuggestedarticleSetting.caseFields = knowledgecasefieldlistSetting;
        knowledgesuggestedarticleSetting.useSuggestedArticlesForCase = true;
        knowledgesuggestedarticleSetting.workOrderFields = nowledgeworkorderfieldlistSetting;
        knowledgesuggestedarticleSetting.workOrderLineItemFields = knowledgeworkorderlineitemfieldlistSetting;

        ScratchOrgSettings.KnowledgeLanguage knowledgelanguageSetting = new ScratchOrgSettings.KnowledgeLanguage();
        knowledgelanguageSetting.active = true;
        knowledgelanguageSetting.defaultAssignee = '';
        knowledgelanguageSetting.defaultAssigneeType = ScratchOrgSettings.KnowledgeLanguageLookupValueType.user;
        knowledgelanguageSetting.defaultReviewer = '';
        knowledgelanguageSetting.defaultReviewerType = ScratchOrgSettings.KnowledgeLanguageLookupValueType.user;
        knowledgelanguageSetting.name = '';

        ScratchOrgSettings.KnowledgeLanguageSettings knowledgelanguagelistSetting = new ScratchOrgSettings.KnowledgeLanguageSettings();
        knowledgelanguagelistSetting.language = knowledgelanguageSetting;

        ScratchOrgSettings.KnowledgeSitesSettings knowledgesiteSetting = new ScratchOrgSettings.KnowledgeSitesSettings();
        knowledgesiteSetting.site = new List<String>();

        ScratchOrgSettings.KnowledgeCaseSettings knowledgecaseSetting = new ScratchOrgSettings.KnowledgeCaseSettings();
        knowledgecaseSetting.articlePDFCreationProfile = '';
        knowledgecaseSetting.articlePublicSharingSites = knowledgesiteSetting;
        knowledgecaseSetting.articlePublicSharingCommunities = knowledgesiteSetting;
        knowledgecaseSetting.articlePublicSharingSitesChatterAnswers = knowledgesiteSetting;
        knowledgecaseSetting.assignTo = '';
        knowledgecaseSetting.customizationClass = '';
        knowledgecaseSetting.defaultContributionArticleType = '';
        knowledgecaseSetting.editor = ScratchOrgSettings.KnowledgeCaseEditor.simple;
        knowledgecaseSetting.enableArticleCreation = true;
        knowledgecaseSetting.enableArticlePublicSharingSites = true;
        knowledgecaseSetting.useProfileForPDFCreation = true;

        ScratchOrgSettings.KnowledgeAnswerSettings knowledgeanswerSetting = new ScratchOrgSettings.KnowledgeAnswerSettings();
        knowledgeanswerSetting.assignTo = '';
        knowledgeanswerSetting.defaultArticleType = '';
        knowledgeanswerSetting.enableArticleCreation = true;

        ScratchOrgSettings.KnowledgeSettings knowledgeSetting = new ScratchOrgSettings.KnowledgeSettings();
        knowledgeSetting.answers = knowledgeanswerSetting;
        knowledgeSetting.cases = knowledgecaseSetting;
        knowledgeSetting.defaultLanguage = 'en_US';
        knowledgeSetting.languages = knowledgelanguagelistSetting;
        knowledgeSetting.enableChatterQuestionKBDeflection = true;
        knowledgeSetting.enableCreateEditOnArticlesTab = true;
        knowledgeSetting.enableExternalMediaContent = true;
        knowledgeSetting.enableKnowledge = true;
        knowledgeSetting.showArticleSummariesCustomerPortal = true;
        knowledgeSetting.showArticleSummariesInternalApp = true;
        knowledgeSetting.showArticleSummariesPartnerPortal = true;
        knowledgeSetting.showValidationStatusField = true;
        knowledgeSetting.suggestedArticles = knowledgesuggestedarticleSetting;

        knowledgeSetting.getSetting();



        ScratchOrgSettings.MappingFields mappingfieldSetting = new ScratchOrgSettings.MappingFields();
        mappingfieldSetting.inputField = '';
        mappingfieldSetting.outputField = '';

        ScratchOrgSettings.ObjectMapping objectmappingSetting = new ScratchOrgSettings.ObjectMapping();
        objectmappingSetting.inputObject = '';
        objectmappingSetting.mappingFields = new List<ScratchOrgSettings.MappingFields>{mappingfieldSetting};
        objectmappingSetting.outputObject = '';

        ScratchOrgSettings.LeadConvertSettings leadconvertSetting = new ScratchOrgSettings.LeadConvertSettings();
        leadconvertSetting.allowOwnerChange = true;
        leadconvertSetting.objectMapping = new List<ScratchOrgSettings.ObjectMapping>{objectmappingSetting};

        leadconvertSetting.getSetting();


        ScratchOrgSettings.LiveAgentSettings liveagentSetting = new ScratchOrgSettings.LiveAgentSettings();
        liveagentSetting.enableLiveAgent = true;

        liveagentSetting.getSetting();


        ScratchOrgSettings.LiveMessageSettings livemessageSetting = new ScratchOrgSettings.LiveMessageSettings();
        livemessageSetting.enableLiveMessage = true;

        livemessageSetting.getSetting();


        ScratchOrgSettings.MacroSettings macroSetting = new ScratchOrgSettings.MacroSettings();
        macroSetting.enableAdvancedSearch = true;
        macroSetting.macrosInFolders = true;

        macroSetting.getSetting();


        ScratchOrgSettings.NameSettings nameSetting = new ScratchOrgSettings.NameSettings();
        nameSetting.enableMiddleName = true;
        nameSetting.enableNameSuffix = true;

        nameSetting.getSetting();


        ScratchOrgSettings.OmniChannelSettings omniChannelSettings = new ScratchOrgSettings.OmniChannelSettings();
        omniChannelSettings.enableOmniChannel = true;
        omniChannelSettings.enableOmniSkillsRouting = true;

        omniChannelSettings.getSetting();


        ScratchOrgSettings.FindSimilarOppFilter findsimilaroppfilterSetting = new ScratchOrgSettings.FindSimilarOppFilter();
        findsimilaroppfilterSetting.similarOpportunitiesDisplayColumns = '';
        findsimilaroppfilterSetting.similarOpportunitiesMatchFields = '';

        ScratchOrgSettings.OpportunitySettings opportunitySetting = new ScratchOrgSettings.OpportunitySettings();
        opportunitySetting.enableUpdateReminders = true;
        opportunitySetting.autoActivateNewReminders = true;
        opportunitySetting.enableFindSimilarOpportunities = true;
        opportunitySetting.findSimilarOppFilter = findsimilaroppfilterSetting;
        opportunitySetting.enableOpportunityTeam = true;
        opportunitySetting.promptToAddProducts = true;

        opportunitySetting.getSetting();


        ScratchOrgSettings.OrganizationSettingsDetail organizationsettingdetailSetting = new ScratchOrgSettings.OrganizationSettingsDetail();
        organizationsettingdetailSetting.settingName = '';
        organizationsettingdetailSetting.setttingValue = true;

        ScratchOrgSettings.OrgPreferenceSettings orgpreferenceSetting = new ScratchOrgSettings.OrgPreferenceSettings();
        orgpreferenceSetting.preferences = new List<ScratchOrgSettings.OrganizationSettingsDetail>{organizationsettingdetailSetting};

        orgpreferenceSetting.getSetting();


        ScratchOrgSettings.OrderSettings orderSetting = new ScratchOrgSettings.OrderSettings();
        orderSetting.enableNegativeQuantity = true;
        orderSetting.enableOrders = true;
        orderSetting.enableReductionOrders = true;
        orderSetting.enableZeroQuantity = true;

        orderSetting.getSetting();



        ScratchOrgSettings.PathAssistantSettings pathassistantSetting = new ScratchOrgSettings.PathAssistantSettings();
        pathassistantSetting.pathAssistantForOpportunityEnabled = true;
        pathassistantSetting.pathAssistantEnabled = true;

        pathassistantSetting.getSetting();


        ScratchOrgSettings.ProductSettings productSetting = new ScratchOrgSettings.ProductSettings();
        productSetting.enableCascadeActivateToRelatedPrices = true;
        productSetting.enableQuantitySchedule = true;
        productSetting.enableRevenueSchedule = true;

        productSetting.getSetting();


        ScratchOrgSettings.ProfileSessionSetting profilesessionSetting = new ScratchOrgSettings.ProfileSessionSetting();
        profilesessionSetting.forceLogout = true;
        profilesessionSetting.profile = '';
        profilesessionSetting.requiredSessionLevel = ScratchOrgSettings.SessionSecurityLevel.LOW ;
        profilesessionSetting.sessionPersistence = true;
        profilesessionSetting.sessionTimeout = 15;
        profilesessionSetting.sessionTimeoutWarning = '';

        profilesessionSetting.getSetting();


        ScratchOrgSettings.QuoteSettings quoteSetting = new ScratchOrgSettings.QuoteSettings();
        quoteSetting.enableQuote = true;

        quoteSetting.getSetting();


        ScratchOrgSettings.ObjectSearchSetting objectsearchSetting = new ScratchOrgSettings.ObjectSearchSetting();
        objectsearchSetting.enhancedLookupEnabled = true;
        objectsearchSetting.lookupAutoCompleteEnabled = true;
        objectsearchSetting.name = '';
        objectsearchSetting.resultsPerPageCount = 1;

        ScratchOrgSettings.SearchSettingsByObject searchsettingsbyobjectSetting = new ScratchOrgSettings.SearchSettingsByObject ();
        searchsettingsbyobjectSetting.searchSettingsByObject = objectsearchSetting;

        ScratchOrgSettings.SearchSettings searchSetting = new ScratchOrgSettings.SearchSettings();
        searchSetting.documentContentSearchEnabled = true;
        searchSetting.optimizeSearchForCJKEnabled   = true;
        searchSetting.recentlyViewedUsersForBlankLookupEnabled = true;
        searchSetting.searchSettingsByObject = searchsettingsbyobjectSetting;
        searchSetting.sidebarAutoCompleteEnabled = true;
        searchSetting.sidebarDropDownListEnabled = true;
        searchSetting.sidebarLimitToItemsIOwnCheckboxEnabled = true;
        searchSetting.singleSearchResultShortcutEnabled = true;
        searchSetting.spellCorrectKnowledgeSearchEnabled = true;

        searchSetting.getSetting();



        ScratchOrgSettings.SessionSettings sessionSetting = new ScratchOrgSettings.SessionSettings();
        sessionSetting.disableTimeoutWarning = true;
        sessionSetting.enableCSPOnEmail = true;
        sessionSetting.enableCSRFOnGet = true;
        sessionSetting.enableCSRFOnPost = true;
        sessionSetting.enableCacheAndAutocomplete = true;
        sessionSetting.enableClickjackNonsetupSFDC = true;
        sessionSetting.enableClickjackNonsetupUser = true;
        sessionSetting.enableClickjackNonsetupUserHeaderless = true;
        sessionSetting.enableClickjackSetup = true;
        sessionSetting.enableContentSniffingProtection = true;
        sessionSetting.enablePostForSessions = true;
        sessionSetting.enableSMSIdentity = true;
        sessionSetting.enableUpgradeInsecureRequests = true;
        sessionSetting.enableXssProtection = true;
        sessionSetting.enforceIpRangesEveryRequest = true;
        sessionSetting.forceLogoutOnSessionTimeout = true;
        sessionSetting.forceRelogin = true;
        sessionSetting.hstsOnForcecomSites = true;
        sessionSetting.identityConfirmationOnEmailChange = true;
        sessionSetting.identityConfirmationOnTwoFactorRegistrationEnabled = true;
        sessionSetting.lockSessionsToDomain = true;
        sessionSetting.lockSessionsToIp = true;
        sessionSetting.logoutURL = '';
        sessionSetting.redirectionWarning = true;
        sessionSetting.referrerPolicy = true;
        sessionSetting.requireHttpOnly = true;
        sessionSetting.requireHttps = true;
        sessionSetting.sessionTimeout = ScratchOrgSettings.SessionTimeout.FifteenMinutes;


        ScratchOrgSettings.PasswordPolicies passwordpolicieSetting = new ScratchOrgSettings.PasswordPolicies();
        passwordpolicieSetting.apiOnlyUserHomePageURL = '';
        passwordpolicieSetting.complexity = ScratchOrgSettings.Complexity.NoRestriction;
        passwordpolicieSetting.expiration = ScratchOrgSettings.Expiration.Never;
        passwordpolicieSetting.minimumPasswordLifetime = true;
        passwordpolicieSetting.historyRestriction = '0';
        passwordpolicieSetting.lockoutInterval = ScratchOrgSettings.LockoutInterval.FifteenMinutes;
        passwordpolicieSetting.maxLoginAttempts = ScratchOrgSettings.MaxLoginAttempts.NoLimit;
        passwordpolicieSetting.minimumPasswordLength = '5';
        passwordpolicieSetting.obscureSecretAnswer = true;
        passwordpolicieSetting.passwordAssistanceMessage = '';
        passwordpolicieSetting.passwordAssistanceURL = '';
        passwordpolicieSetting.questionRestriction = ScratchOrgSettings.QuestionRestriction.None;


        ScratchOrgSettings.IpRange iprangeSetting = new ScratchOrgSettings.IpRange();
        iprangeSetting.description = '';
        iprangeSetting.endRange = '';
        iprangeSetting.start = '';

        ScratchOrgSettings.NetworkAccess networkaccessSetting = new ScratchOrgSettings.NetworkAccess();
        networkaccessSetting.ipRanges = new List<ScratchOrgSettings.IpRange>{iprangeSetting};

        ScratchOrgSettings.SecuritySettings securitySetting = new ScratchOrgSettings.SecuritySettings();
        securitySetting.networkAccess = networkaccessSetting;
        securitySetting.passwordPolicies = passwordpolicieSetting;
        securitySetting.sessionSettings = sessionSetting;

        securitySetting.getSetting();

        ScratchOrgSettings.SocialCustomerServiceSettings socialcustomerserviceSetting = new ScratchOrgSettings.SocialCustomerServiceSettings();
        socialcustomerserviceSetting.caseSubjectOption = ScratchOrgSettings.CaseSubjectOption.SocialPostSource;

        socialcustomerserviceSetting.getSetting();



        ScratchOrgSettings.Territory2Settings territory2Setting = new ScratchOrgSettings.Territory2Settings();
        territory2Setting.defaultAccountAccessLevel = '';
        territory2Setting.defaultCaseAccessLevel = '';
        territory2Setting.defaultContactAccessLevel = '';
        territory2Setting.defaultOpportunityAccessLevel = '';

        territory2Setting.getSetting();


        ScratchOrgSettings.Settings settings = new ScratchOrgSettings.Settings();
        settings.accountSettings = accSettings;
        settings.activitiesSettings = activitySettings;
        settings.addressSettings = addresSetting;
        settings.businessHoursSettings = businesshourSetting;
        settings.caseSettings = caseSetting;
        settings.chatterAnswersSettings = chatteranswerSetting;
        settings.companySettings = companySetting;
        settings.contractSettings = contractSetting;
        settings.entitlementSettings = entitlementSetting;
        settings.fieldServiceSettings = fieldserviceSetting;
        settings.fileUploadAndDownloadSecuritySettings = fileupoadandownloadSetting;
        settings.forecastingSettings = forecastingSetting;
        settings.ideasSettings = ideaSetting;
        settings.ioTSettings = iotSetting;
        settings.knowledgeSettings = knowledgeSetting;
        settings.leadConvertSettings = leadconvertSetting;
        settings.liveAgentSettings = liveagentSetting;
        settings.liveMessageSettings = livemessageSetting;
        settings.macroSettings = macroSetting;
        settings.nameSettings = nameSetting;
        settings.omniChannelSettings = omniChannelSettings;
        settings.opportunitySettings = opportunitySetting;
        settings.orderSettings = orderSetting;
        settings.orgPreferenceSettings = orgpreferenceSetting;
        settings.pathAssistantSettings = pathassistantSetting;
        settings.productSettings = productSetting;
        settings.profileSessionSetting = profilesessionSetting;
        settings.quoteSettings = quoteSetting;
        settings.searchSettings = searchSetting;
        settings.securitySettings = securitySetting;
        settings.socialCustomerServiceSettings = socialcustomerserviceSetting;
        settings.territory2Settings = territory2Setting;

        settings.getSetting();
    }

    static testMethod void testNewOrgdefinitionFile(){

        Org__c devHubOrg = [SELECT Id, Name FROM Org__c WHERE  SFDC_Org_ID__c = 'orgId1'];
        Org__c Org = [SELECT Id, Name FROM Org__c WHERE  SFDC_Org_ID__c = 'orgId'];

        PageReference pageref = Page.NewScratchOrgDefinition;
        Test.setCurrentPage(pageref);

        Scratch_Org_Definition__c scOrgDef = new Scratch_Org_Definition__c();
        ApexPages.StandardController sc = new ApexPages.StandardController(scOrgDef);
        ScratchOrgDefinitionController controller = new ScratchOrgDefinitionController(sc);
        controller.componentMode = 'newStd';

        Test.startTest();
        ScratchOrgController scOrgController = new ScratchOrgController();

        //SetUp asserts.
        Map<String,String> assertNameMap = new ScratchOrgSettings.Settings().getSetting();
        List<SelectOption> assertPrefsSelectOption = OrgPreferencesHandler.prepareSettingsOptions(assertNameMap);

        System.assertEquals(assertNameMap ,scOrgController.settingsNameMap);
        System.assertEquals(scOrgController.orgSettings, assertPrefsSelectOption);

        scOrgController.templateName = 'Test';
        scOrgController.devHubOrgId = devHubOrg.Id;
        scOrgController.orgTemplate.features = new List<String>{'API','AuthorApex'};

        //Test On change function.
        scOrgController.selectedOrgSetting = 'accountSettings';
        scOrgController.getRenderedSettings();
        scOrgController.getRenderPageBlockTable();

        // No messages from catch
        System.assert(ApexPages.getMessages().isEmpty());


        // Set enableAccountOwnerReport to True
        ApexPages.currentPage().getParameters().put('settingAttribute','enableAccountOwnerReport');
        ApexPages.currentPage().getParameters().put('settingValue','true');

        scOrgController.saveToSettingsMap();

        // Set enableAccountTeams to False
        ApexPages.currentPage().getParameters().put('settingAttribute','enableAccountTeams');
        ApexPages.currentPage().getParameters().put('settingValue','false');

        scOrgController.saveToSettingsMap();

        // Set showViewHierarchyLink to True
        ApexPages.currentPage().getParameters().put('settingAttribute','showViewHierarchyLink');
        ApexPages.currentPage().getParameters().put('settingValue','true');

        scOrgController.saveToSettingsMap();

        // Set enableAccountOwnerReport to Default again.
        ApexPages.currentPage().getParameters().put('settingAttribute','enableAccountOwnerReport');
        ApexPages.currentPage().getParameters().put('settingValue','null');

        scOrgController.saveToSettingsMap();

        //Test On change function.
        scOrgController.selectedOrgSetting = '-- None --';
        scOrgController.getRenderedSettings();

        scOrgController.clearSelection();
        scOrgController.getRenderedSettings();

        scOrgController.newTemplate();

        String jsonAseert = '{"settings":{"accountSettings":{"showViewHierarchyLink":true,"enableAccountTeams":false}},"language":"en_US","hasSampleData":false,"features":["API","AuthorApex"],"edition":"Developer","country":"US","adminEmail":"cgarcia@copado.com"}';
        Scratch_Org_Definition__c finalSco = [SELECT Id, Name, Scratch_Org_Definition_JSON__c FROM Scratch_Org_Definition__c WHERE Name = 'Test' LIMIT 1];
        String finalScoString = JSON.serialize(JSON.deserialize(finalSco.Scratch_Org_Definition_JSON__c, SfdxAPIHelper.ScratchOrgDefinition.class), true);
        System.assertEquals(jsonAseert, finalScoString);

        Test.stopTest();
    }

    static testMethod void testNewOrgdefinitionFileWithOutSettings(){

        Org__c devHubOrg = [SELECT Id, Name FROM Org__c WHERE  SFDC_Org_ID__c = 'orgId1'];
        Org__c Org = [SELECT Id, Name FROM Org__c WHERE  SFDC_Org_ID__c = 'orgId'];

        PageReference pageref = Page.NewScratchOrgDefinition;
        Test.setCurrentPage(pageref);

        Scratch_Org_Definition__c scOrgDef = new Scratch_Org_Definition__c();
        ApexPages.StandardController sc = new ApexPages.StandardController(scOrgDef);
        ScratchOrgDefinitionController controller = new ScratchOrgDefinitionController(sc);
        controller.componentMode = 'newStd';

        Test.startTest();
        ScratchOrgController scOrgController = new ScratchOrgController();

        //SetUp asserts.
        Map<String,String> assertNameMap = new ScratchOrgSettings.Settings().getSetting();
        List<SelectOption> assertPrefsSelectOption = OrgPreferencesHandler.prepareSettingsOptions(assertNameMap);

        System.assertEquals(assertNameMap ,scOrgController.settingsNameMap);
        System.assertEquals(scOrgController.orgSettings, assertPrefsSelectOption);

        scOrgController.templateName = 'Test';
        scOrgController.devHubOrgId = devHubOrg.Id;
        scOrgController.orgTemplate.features = new List<String>{'API','AuthorApex'};

        //Test On change function.
        scOrgController.selectedOrgSetting = 'accountSettings';
        scOrgController.getRenderedSettings();

        // No messages from catch
        System.assert(ApexPages.getMessages().isEmpty());

        //Test On change function.
        scOrgController.selectedOrgSetting = 'caseSettings';
        scOrgController.getRenderedSettings();

        // No messages from catch
        System.assert(ApexPages.getMessages().isEmpty());

        //Test On change function.
        scOrgController.selectedOrgSetting = 'activitiesSettings';
                scOrgController.getRenderedSettings();

        // No messages from catch
        System.assert(ApexPages.getMessages().isEmpty());

        scOrgController.newTemplate();

        String jsonAssert = '{"language":"en_US","hasSampleData":false,"features":["API","AuthorApex"],"edition":"Developer","country":"US","adminEmail":"cgarcia@copado.com"}';
        Scratch_Org_Definition__c finalSco = [SELECT Id, Name, Scratch_Org_Definition_JSON__c FROM Scratch_Org_Definition__c WHERE Name = 'Test' LIMIT 1];
        String finalScoString = JSON.serialize(JSON.deserialize(finalSco.Scratch_Org_Definition_JSON__c, SfdxAPIHelper.ScratchOrgDefinition.class), true);
        System.assertEquals(jsonAssert, finalScoString);
        Test.stopTest();
    }

    static testMethod void testComplexJsonProcessAndSave(){
        Org__c devHubOrg = [SELECT Id, Name FROM Org__c WHERE  SFDC_Org_ID__c = 'orgId1'];
        Org__c Org = [SELECT Id, Name FROM Org__c WHERE  SFDC_Org_ID__c = 'orgId'];

        PageReference pageref = Page.NewScratchOrgDefinition;
        Test.setCurrentPage(pageref);

        Scratch_Org_Definition__c scOrgDef = new Scratch_Org_Definition__c();
        ApexPages.StandardController sc = new ApexPages.StandardController(scOrgDef);
        ScratchOrgDefinitionController controller = new ScratchOrgDefinitionController(sc);
        controller.componentMode = 'newStd';

        Test.startTest();
        ScratchOrgController scOrgController = new ScratchOrgController();

        //SetUp asserts.
        Map<String,String> assertNameMap = new ScratchOrgSettings.Settings().getSetting();
        List<SelectOption> assertPrefsSelectOption = OrgPreferencesHandler.prepareSettingsOptions(assertNameMap);

        System.assertEquals(assertNameMap ,scOrgController.settingsNameMap);
        System.assertEquals(scOrgController.orgSettings, assertPrefsSelectOption);

        scOrgController.templateName = 'Test';
        scOrgController.devHubOrgId = devHubOrg.Id;
        scOrgController.orgTemplate.features = new List<String>{'API','AuthorApex'};

        //Test On change function.
        scOrgController.selectedOrgSetting = 'caseSettings';
        scOrgController.getRenderedSettings();

        // Set parameters to show json editor
        ApexPages.currentPage().getParameters().put('settingAttribute','emailToCase');
        ApexPages.currentPage().getParameters().put('settingObject','caseSettings');
        //Shows the editor.
        scOrgController.processJsonType();

        //Setup assert
        ScratchOrgSettings.EmailToCaseSettings emailToCase = new ScratchOrgSettings.EmailToCaseSettings();
        String caseSettingProcessJsonResult = JSON.serialize(emailToCase);

        String getCaseSettingJsonAttr = scOrgController.getAttributeJSON();

        System.assertEquals(caseSettingProcessJsonResult, getCaseSettingJsonAttr);

        //Save attribute without List attributes.
        scOrgController.jsonCode = getCaseSettingJsonAttr;
        scOrgController.saveJson();

        //CheckErrors saving JsonCode
        System.assertEquals(String.isBlank(scOrgController.getErrorMessage()), ApexPages.getMessages().isEmpty());

        //Test On change function.
        scOrgController.selectedOrgSetting = 'addressSettings';
        scOrgController.getRenderedSettings();

        // Set parameters to show json editor
        ApexPages.currentPage().getParameters().put('settingAttribute','countries');
        ApexPages.currentPage().getParameters().put('settingObject','addressSettings');
        //Shows the editor.
        scOrgController.processJsonType();

        //Setup assert
        List<ScratchOrgSettings.Country> countries = new List<ScratchOrgSettings.Country>{new ScratchOrgSettings.Country()};
        String addressSettingsProcessJsonResult = JSON.serialize(countries);

        String getAddressSettingJsonAttr = scOrgController.getAttributeJSON();

        System.assertEquals(addressSettingsProcessJsonResult, getAddressSettingJsonAttr);

        //Save attribute WITH List attributes.
        scOrgController.jsonCode = getAddressSettingJsonAttr;
        scOrgController.saveJson();

        Test.stopTest();
    }*/
}