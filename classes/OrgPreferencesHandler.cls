/**
 * Created by mertyalti on 27/01/2018.
 */

public without sharing class OrgPreferencesHandler {
    public static Map<String, List<SelectOption>> prepareSelectOptions() {
        Map<String, List<SelectOption>> orgPreferences = new Map<String, List<SelectOption>>();
        List<SelectOption> generalPreferences = new List<SelectOption>();
        generalPreferences.add(new SelectOption('AnalyticsSharingEnable', 'AnalyticsSharingEnable'));
        generalPreferences.add(new SelectOption('AsyncSaveEnabled', 'AsyncSaveEnabled'));
        generalPreferences.add(new SelectOption('ChatterEnabled', 'ChatterEnabled'));
        generalPreferences.add(new SelectOption('DisableParallelApexTesting', 'DisableParallelApexTesting'));
        generalPreferences.add(new SelectOption('EnhancedEmailEnabled', 'EnhancedEmailEnabled'));
        generalPreferences.add(new SelectOption('EventLogWaveIntegEnabled', 'EventLogWaveIntegEnabled'));
        generalPreferences.add(new SelectOption('LoginForensicsEnabled', 'LoginForensicsEnabled'));
        generalPreferences.add(new SelectOption('NetworksEnabled', 'NetworksEnabled'));
        generalPreferences.add(new SelectOption('NotesReservedPref01', 'NotesReservedPref01'));
        generalPreferences.add(new SelectOption('OfflineDraftsEnabled', 'OfflineDraftsEnabled'));
        generalPreferences.add(new SelectOption('PathAssistantsEnabled', 'PathAssistantsEnabled'));
        generalPreferences.add(new SelectOption('S1DesktopEnabled', 'S1DesktopEnabled'));
        generalPreferences.add(new SelectOption('S1EncryptedStoragePref2', 'S1EncryptedStoragePref2'));
        generalPreferences.add(new SelectOption('S1OfflinePref', 'S1OfflinePref'));
        generalPreferences.add(new SelectOption('SelfSetPasswordInApi', 'SelfSetPasswordInApi'));
        generalPreferences.add(new SelectOption('SendThroughGmailPref', 'SendThroughGmailPref'));
        generalPreferences.add(new SelectOption('SocialProfilesEnable', 'SocialProfilesEnable'));
        generalPreferences.add(new SelectOption('Translation', 'Translation'));
        generalPreferences.add(new SelectOption('VoiceEnabled', 'VoiceEnabled'));
        orgPreferences.put('General Settings', generalPreferences);

        List<SelectOption> accountPreferences = new List<SelectOption>();
        accountPreferences.add(new SelectOption('IsAccountTeamsEnabled', 'IsAccountTeamsEnabled'));
        accountPreferences.add(new SelectOption('ShowViewHierarchyLink', 'ShowViewHierarchyLink'));
        orgPreferences.put('Account Settings', accountPreferences);

        List<SelectOption> activityPreferences = new List<SelectOption>();
        activityPreferences.add(new SelectOption('IsActivityRemindersEnabled', 'IsActivityRemindersEnabled'));
        activityPreferences.add(new SelectOption('IsDragAndDropSchedulingEnabled', 'IsDragAndDropSchedulingEnabled'));
        activityPreferences.add(new SelectOption('IsEmailTrackingEnabled', 'IsEmailTrackingEnabled'));
        activityPreferences.add(new SelectOption('IsGroupTasksEnabled', 'IsGroupTasksEnabled'));
        activityPreferences.add(new SelectOption('IsMultidayEventsEnabled', 'IsMultidayEventsEnabled'));
        activityPreferences.add(new SelectOption('IsRecurringEventsEnabled', 'IsRecurringEventsEnabled'));
        activityPreferences.add(new SelectOption('IsRecurringTasksEnabled', 'IsRecurringTasksEnabled'));
        activityPreferences.add(new SelectOption('IsSidebarCalendarShortcutEnabled', 'IsSidebarCalendarShortcutEnabled'));
        activityPreferences.add(new SelectOption('IsSimpleTaskCreateUIEnabled', 'IsSimpleTaskCreateUIEnabled'));
        activityPreferences.add(new SelectOption('ShowEventDetailsMultiUserCalendar', 'ShowEventDetailsMultiUserCalendar'));
        activityPreferences.add(new SelectOption('ShowHomePageHoverLinksForEvents', 'ShowHomePageHoverLinksForEvents'));
        activityPreferences.add(new SelectOption('ShowMyTasksHoverLinks', 'ShowMyTasksHoverLinks'));
        orgPreferences.put('Activities Settings', activityPreferences);

        List<SelectOption> contractPreferences = new List<SelectOption>();
        contractPreferences.add(new SelectOption('AutoCalculateEndDate', 'AutoCalculateEndDate'));
        contractPreferences.add(new SelectOption('IsContractHistoryTrackingEnabled', 'IsContractHistoryTrackingEnabled'));
        contractPreferences.add(new SelectOption('NotifyOwnersOnContractExpiration', 'NotifyOwnersOnContractExpiration'));
        orgPreferences.put('Contract Settings', contractPreferences);

        List<SelectOption> entitlementPreferences = new List<SelectOption>();
        entitlementPreferences.add(new SelectOption('AssetLookupLimitedToActiveEntitlementsOnAccount', 'AssetLookupLimitedToActiveEntitlementsOnAccount'));
        entitlementPreferences.add(new SelectOption('AssetLookupLimitedToActiveEntitlementsOnContact', 'AssetLookupLimitedToActiveEntitlementsOnContact'));
        entitlementPreferences.add(new SelectOption('AssetLookupLimitedToSameAccount', 'AssetLookupLimitedToSameAccount'));
        entitlementPreferences.add(new SelectOption('AssetLookupLimitedToSameContact', 'AssetLookupLimitedToSameContact'));
        entitlementPreferences.add(new SelectOption('IsEntitlementsEnabled', 'IsEntitlementsEnabled'));
        entitlementPreferences.add(new SelectOption('EntitlementLookupLimitedToActiveStatus', 'EntitlementLookupLimitedToActiveStatus'));
        entitlementPreferences.add(new SelectOption('EntitlementLookupLimitedToSameAccount', 'EntitlementLookupLimitedToSameAccount'));
        entitlementPreferences.add(new SelectOption('EntitlementLookupLimitedToSameAsset', 'EntitlementLookupLimitedToSameAsset'));
        entitlementPreferences.add(new SelectOption('EntitlementLookupLimitedToSameContact', 'EntitlementLookupLimitedToSameContact'));
        orgPreferences.put('Entitlement Settings', entitlementPreferences);

        List<SelectOption> forecastingPreferences = new List<SelectOption>();
        forecastingPreferences.add(new SelectOption('IsForecastsEnabled', 'IsForecastsEnabled'));
        orgPreferences.put('Forecasting Settings', forecastingPreferences);

        List<SelectOption> ideaPreferences = new List<SelectOption>();
        ideaPreferences.add(new SelectOption('IsChatterProfileEnabled', 'IsChatterProfileEnabled'));
        ideaPreferences.add(new SelectOption('IsIdeaThemesEnabled', 'IsIdeaThemesEnabled'));
        ideaPreferences.add(new SelectOption('IsIdeasEnabled', 'IsIdeasEnabled'));
        ideaPreferences.add(new SelectOption('IsIdeasReputationEnabled', 'IsIdeasReputationEnabled'));
        orgPreferences.put('Ideas Settings', ideaPreferences);

        List<SelectOption> knowledgePreferences = new List<SelectOption>();
        knowledgePreferences.add(new SelectOption('IsCreateEditOnArticlesTabEnabled', 'IsCreateEditOnArticlesTabEnabled'));
        knowledgePreferences.add(new SelectOption('IsExternalMediaContentEnabled', 'IsExternalMediaContentEnabled'));
        knowledgePreferences.add(new SelectOption('IsKnowledgeEnabled', 'IsKnowledgeEnabled'));
        knowledgePreferences.add(new SelectOption('ShowArticleSummariesCustomerPortal', 'ShowArticleSummariesCustomerPortal'));
        knowledgePreferences.add(new SelectOption('ShowArticleSummariesInternalApp', 'ShowArticleSummariesInternalApp'));
        knowledgePreferences.add(new SelectOption('ShowArticleSummariesPartnerPortal', 'ShowArticleSummariesPartnerPortal'));
        knowledgePreferences.add(new SelectOption('ShowValidationStatusField', 'ShowValidationStatusField'));
        orgPreferences.put('Knowledge Settings', knowledgePreferences);

        List<SelectOption> liveAgentPreferences = new List<SelectOption>();
        liveAgentPreferences.add(new SelectOption('IsLiveAgentEnabled', 'IsLiveAgentEnabled'));
        orgPreferences.put('Live Agent Settings', liveAgentPreferences);

        List<SelectOption> marketingActionPreferences = new List<SelectOption>();
        marketingActionPreferences.add(new SelectOption('IsMarketingActionEnabled', 'IsMarketingActionEnabled'));
        orgPreferences.put('Marketing Action Settings', marketingActionPreferences);

        List<SelectOption> namePreferences = new List<SelectOption>();
        namePreferences.add(new SelectOption('IsMiddleNameEnabled', 'IsMiddleNameEnabled'));
        namePreferences.add(new SelectOption('IsNameSuffixEnabled', 'IsNameSuffixEnabled'));
        orgPreferences.put('Name Settings', namePreferences);

        List<SelectOption> opportunityPreferences = new List<SelectOption>();
        opportunityPreferences.add(new SelectOption('IsOpportunityTeamEnabled', 'IsOpportunityTeamEnabled'));
        orgPreferences.put('Opportunity Settings', opportunityPreferences);

        List<SelectOption> orderPreferences = new List<SelectOption>();
        orderPreferences.add(new SelectOption('IsNegativeQuantityEnabled', 'IsNegativeQuantityEnabled'));
        orderPreferences.add(new SelectOption('IsOrdersEnabled', 'IsOrdersEnabled'));
        orderPreferences.add(new SelectOption('IsReductionOrdersEnabled', 'IsReductionOrdersEnabled'));
        orgPreferences.put('Order Settings', orderPreferences);

        List<SelectOption> personalJourneyPreferences = new List<SelectOption>();
        personalJourneyPreferences.add(new SelectOption('IsExactTargetForSalesforceAppsEnabled', 'IsExactTargetForSalesforceAppsEnabled'));
        orgPreferences.put('Personal Journey Settings', personalJourneyPreferences);

        List<SelectOption> productPreferences = new List<SelectOption>();
        productPreferences.add(new SelectOption('IsCascadeActivateToRelatedPricesEnabled', 'IsCascadeActivateToRelatedPricesEnabled'));
        productPreferences.add(new SelectOption('IsQuantityScheduleEnabled', 'IsQuantityScheduleEnabled'));
        productPreferences.add(new SelectOption('IsRevenueScheduleEnabled', 'IsRevenueScheduleEnabled'));
        orgPreferences.put('Product Settings', productPreferences);

        List<SelectOption> quotePreferences = new List<SelectOption>();
        quotePreferences.add(new SelectOption('IsQuoteEnabled', 'IsQuoteEnabled'));
        orgPreferences.put('Quote Settings', quotePreferences);

        List<SelectOption> searchPreferences = new List<SelectOption>();
        searchPreferences.add(new SelectOption('DocumentContentSearchEnabled', 'DocumentContentSearchEnabled'));
        searchPreferences.add(new SelectOption('OptimizeSearchForCjkEnabled', 'OptimizeSearchForCjkEnabled'));
        searchPreferences.add(new SelectOption('RecentlyViewedUsersForBlankLookupEnabled', 'RecentlyViewedUsersForBlankLookupEnabled'));
        searchPreferences.add(new SelectOption('SidebarAutoCompleteEnabled', 'SidebarAutoCompleteEnabled'));
        searchPreferences.add(new SelectOption('SidebarDropDownListEnabled', 'SidebarDropDownListEnabled'));
        searchPreferences.add(new SelectOption('SidebarLimitToItemsIownCheckboxEnabled', 'SingleSearchResultShortcutEnabled'));
        searchPreferences.add(new SelectOption('SpellCorrectKnowledgeSearchEnabled', 'SpellCorrectKnowledgeSearchEnabled'));
        searchPreferences.add(new SelectOption('SingleSearchResultShortcutEnabled', 'SSingleSearchResultShortcutEnabled'));
        orgPreferences.put('Search Settings', searchPreferences);

        return orgPreferences;
    }

    public static Map<String, String> preparePreferenceToType() {
        Map<String, String> orgPreferences = new Map<String, String>();


        orgPreferences.put('AnalyticsSharingEnable', 'General Settings');
        orgPreferences.put('AsyncSaveEnabled', 'General Settings');
        orgPreferences.put('ChatterEnabled', 'General Settings');
        orgPreferences.put('DisableParallelApexTesting', 'General Settings');
        orgPreferences.put('EnhancedEmailEnabled', 'General Settings');
        orgPreferences.put('EventLogWaveIntegEnabled', 'General Settings');
        orgPreferences.put('LoginForensicsEnabled', 'General Settings');
        orgPreferences.put('NetworksEnabled', 'General Settings');
        orgPreferences.put('NotesReservedPref01', 'General Settings');
        orgPreferences.put('OfflineDraftsEnabled', 'General Settings');
        orgPreferences.put('PathAssistantsEnabled', 'General Settings');
        orgPreferences.put('S1DesktopEnabled', 'General Settings');
        orgPreferences.put('S1EncryptedStoragePref2', 'General Settings');
        orgPreferences.put('S1OfflinePref', 'General Settings');
        orgPreferences.put('SelfSetPasswordInApi', 'General Settings');
        orgPreferences.put('SendThroughGmailPref', 'General Settings');
        orgPreferences.put('SocialProfilesEnable', 'General Settings');
        orgPreferences.put('Translation', 'General Settings');
        orgPreferences.put('VoiceEnabled', 'General Settings');

        orgPreferences.put('IsAccountTeamsEnabled', 'Account Settings');
        orgPreferences.put('ShowViewHierarchyLink', 'Account Settings');

        orgPreferences.put('IsActivityRemindersEnabled', 'Activities Settings');
        orgPreferences.put('IsDragAndDropSchedulingEnabled', 'Activities Settings');
        orgPreferences.put('IsEmailTrackingEnabled', 'Activities Settings');
        orgPreferences.put('IsGroupTasksEnabled', 'Activities Settings');
        orgPreferences.put('IsMultidayEventsEnabled', 'Activities Settings');
        orgPreferences.put('IsRecurringEventsEnabled', 'Activities Settings');
        orgPreferences.put('IsRecurringTasksEnabled', 'Activities Settings');
        orgPreferences.put('IsSidebarCalendarShortcutEnabled', 'Activities Settings');
        orgPreferences.put('IsSimpleTaskCreateUIEnabled', 'Activities Settings');
        orgPreferences.put('ShowEventDetailsMultiUserCalendar', 'Activities Settings');
        orgPreferences.put('ShowHomePageHoverLinksForEvents', 'Activities Settings');
        orgPreferences.put('ShowMyTasksHoverLinks', 'Activities Settings');

        orgPreferences.put('AutoCalculateEndDate', 'Contract Settings');
        orgPreferences.put('IsContractHistoryTrackingEnabled', 'Contract Settings');
        orgPreferences.put('NotifyOwnersOnContractExpiration', 'Contract Settings');

        orgPreferences.put('AssetLookupLimitedToActiveEntitlementsOnAccount', 'Entitlement Settings');
        orgPreferences.put('AssetLookupLimitedToActiveEntitlementsOnContact', 'Entitlement Settings');
        orgPreferences.put('AssetLookupLimitedToSameAccount', 'Entitlement Settings');
        orgPreferences.put('AssetLookupLimitedToSameContact', 'Entitlement Settings');
        orgPreferences.put('IsEntitlementsEnabled', 'Entitlement Settings');
        orgPreferences.put('EntitlementLookupLimitedToActiveStatus', 'Entitlement Settings');
        orgPreferences.put('EntitlementLookupLimitedToSameAccount', 'Entitlement Settings');
        orgPreferences.put('EntitlementLookupLimitedToSameAsset', 'Entitlement Settings');
        orgPreferences.put('EntitlementLookupLimitedToSameContact', 'Entitlement Settings');

        orgPreferences.put('IsForecastsEnabled', 'Forecasting Settings');

        orgPreferences.put('IsChatterProfileEnabled', 'Ideas Settings');
        orgPreferences.put('IsIdeaThemesEnabled', 'Ideas Settings');
        orgPreferences.put('IsIdeasEnabled', 'Ideas Settings');
        orgPreferences.put('IsIdeasReputationEnabled', 'Ideas Settings');

        orgPreferences.put('IsCreateEditOnArticlesTabEnabled', 'Knowledge Settings');
        orgPreferences.put('IsExternalMediaContentEnabled', 'Knowledge Settings');
        orgPreferences.put('IsKnowledgeEnabled', 'Knowledge Settings');
        orgPreferences.put('ShowArticleSummariesCustomerPortal', 'Knowledge Settings');
        orgPreferences.put('ShowArticleSummariesInternalApp', 'Knowledge Settings');
        orgPreferences.put('ShowArticleSummariesPartnerPortal', 'Knowledge Settings');
        orgPreferences.put('ShowValidationStatusField', 'Knowledge Settings');

        orgPreferences.put('IsLiveAgentEnabled', 'Live Agent Settings');

        orgPreferences.put('IsMarketingActionEnabled', 'Marketing Action Settings');

        orgPreferences.put('IsMiddleNameEnabled', 'Name Settings');
        orgPreferences.put('IsNameSuffixEnabled', 'Name Settings');

        orgPreferences.put('IsOpportunityTeamEnabled', 'Opportunity Settings');

        orgPreferences.put('IsNegativeQuantityEnabled', 'Order Settings');
        orgPreferences.put('IsOrdersEnabled', 'Order Settings');
        orgPreferences.put('IsReductionOrdersEnabled', 'Order Settings');

        orgPreferences.put('IsExactTargetForSalesforceAppsEnabled', 'Personal Journey Settings');

        orgPreferences.put('IsCascadeActivateToRelatedPricesEnabled', 'Product Settings');
        orgPreferences.put('IsQuantityScheduleEnabled', 'Product Settings');
        orgPreferences.put('IsRevenueScheduleEnabled', 'Product Settings');

        orgPreferences.put('IsQuoteEnabled', 'Quote Settings');

        orgPreferences.put('DocumentContentSearchEnabled', 'Search Settings');
        orgPreferences.put('OptimizeSearchForCjkEnabled', 'Search Settings');
        orgPreferences.put('RecentlyViewedUsersForBlankLookupEnabled', 'Search Settings');
        orgPreferences.put('SidebarAutoCompleteEnabled', 'Search Settings');
        orgPreferences.put('SidebarDropDownListEnabled', 'Search Settings');
        orgPreferences.put('SidebarLimitToItemsIownCheckboxEnabled', 'Search Settings');
        orgPreferences.put('SpellCorrectKnowledgeSearchEnabled', 'Search Settings');
        orgPreferences.put('SingleSearchResultShortcutEnabled', 'Search Settings');

        return orgPreferences;

    }

    public static Map<String, Set<String>> processPreSelections(List<String> selections) {
        System.debug(loggingLevel.INFO, '*** selections: ' + selections);
        Map<String, String> orgPreferences = OrgPreferencesHandler.preparePreferenceToType();
        System.debug(loggingLevel.INFO, '*** orgPreferences: ' + orgPreferences);
        Map<String, Set<String>> processedSelections = new Map<String, Set<String>>();
        for (String s : selections) {
            if (!orgPreferences.containsKey(s)) continue;
            String preferenceType = orgPreferences.get(s);
            if (processedSelections.containsKey(preferenceType)) {
                Set<String> temp = processedSelections.get(preferenceType);
                temp.add(s);
                processedSelections.put(preferenceType, temp);
            } else {
                Set<String> temp = new Set<String>();
                temp.add(s);
                processedSelections.put(preferenceType, temp);
            }
        }

        return processedSelections;
    }
}