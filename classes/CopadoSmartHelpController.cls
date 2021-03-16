/**
 * Global smart tips component
 * Marking is global since customers may use this in their own pages as well.
 * Global managed components can be used by end users
 * @see CopadoSmartHelpComponent
 * <pre>
 * {@code <copado:CopadoSmartHelpComponent />}
 * </pre>
 * @version 1.0
 * @author Mert YALTI
 *
 */
global with sharing class CopadoSmartHelpController {
    private final String ALWAYS_SHOW = 'Always Show';
    @TestVisible
    private Set<String> removedTips;
    global List<SmartHelp> helpList { get; set; }
    global String tipType { get; set; }
    global String tipValue { get; set; }
    global String tipKey { get; set; }
    global Boolean showTips { get; set; }
    global Boolean tipsAllowed { get; set; }
    global String vfPageName {
        get;
        set {
            vfPageName = vfPageName != null ? vfPageName.replace('copado__', '') : value.replace('copado__', '');
        }
    }

    global copadoSmartHelpController() {
        tipsAllowed = [SELECT Show_Copado_Tips__c FROM User WHERE Id = :UserInfo.getUserId()][0].Show_Copado_Tips__c;
        helpList = new List<SmartHelp>();
        removedTips = new Set<String>();
        showTips = false;
    }

    /**
     * Adds always show type of tips to page when page load is completed
     * @see SmartHelp
     * @return PageReference
     */
    global PageReference setHelpList() {
        if (!tipsAllowed) {
            return null;
        }

        helpList = new List<SmartHelp>();

        for (Copado_Smart_Help__mdt tip : getCopadoSmartHelps()) {
            if (tip.Triggering_Action__c == ALWAYS_SHOW) {
                SmartHelp wrapper = new SmartHelp(tip.DeveloperName, tip.Label, tip.Triggering_Action__c, tip.Triggering_Value__c, tip.Help_Text__c, tip.Help_Text_Url__c);
                helpList.add(wrapper);
            }
        }

        showTips = !helpList.isEmpty();
        return null;
    }

    /**
     * Removes tip from display list
     * @return PageReference
     */
    global PageReference removeTip() {
        if (!tipsAllowed || String.isBlank(tipKey)) {
            return null;
        }

        for (Integer i = helpList.size() - 1; i >= 0; i--) {
            if (helpList[i].apiName == tipKey) {
                helpList.remove(i);
            }
        }

        return null;
    }

    /**
     * Show tips by checking tip type
     * This method is created particularly for grid selections
     * @return PageReference
     */
    global PageReference setTypeList() {
        if (String.isBlank(vfPageName)) {
            vfPageName = ApexPages.currentPage().getParameters().get('pageName');
        }

        if (!tipsAllowed || String.isBlank(tipType)) {
            return null;
        }

        helpList = new List<SmartHelp>();

        for (Copado_Smart_Help__mdt tip : getCopadoSmartHelps()) {
            if (removedTips.contains(tip.DeveloperName)) {
                continue;
            }
            if (tip.Triggering_Action__c != ALWAYS_SHOW && tip.Triggering_Value__c == tipType && isMetadataItemMatched(tip)) { 
                SmartHelp wrapper = new SmartHelp(tip.DeveloperName, tip.Label, tip.Triggering_Action__c, tip.Triggering_Value__c, tip.Help_Text__c, tip.Help_Text_Url__c);
                helpList.add(wrapper);
            }
        }

        showTips = !helpList.isEmpty();
        return null;
    }

    /**
     * General Copado Smart Help query
     */
    private List<Copado_Smart_Help__mdt> getCopadoSmartHelps() {
        return [
            SELECT Base_Page__c, DeveloperName, Help_Text__c, Id, Label, Triggering_Action__c, Triggering_Value__c, Triggering_Metadata_Items__c, Help_Text_Url__c
            FROM Copado_Smart_Help__mdt
            WHERE Active__c = TRUE AND Base_Page__c = :vfPageName
            ORDER BY Triggering_Value__c
        ];
    }

    private Boolean isMetadataItemMatched(Copado_Smart_Help__mdt tip) {
        return (String.isBlank(tip.Triggering_Metadata_Items__c) || tip.Triggering_Metadata_Items__c.split(';').contains(tipValue));
    }

    /**
     * Wrapper class for tips
     */
    global class SmartHelp {
        global String apiName { get; set; }
        global String label { get; set; }
        global String t_action { get; set; }
        global String t_value { get; set; }
        global String helpText { get; set; }
        global String helpUrl { get; set; }

        global SmartHelp(String apiName, String label, String t_action, String t_value, String helpText) {
            this.apiName = apiName;
            this.label = label;
            this.t_action = t_action;
            this.t_value = t_value;
            this.helpText = helpText;
        }

        global SmartHelp(String apiName, String label, String t_action, String t_value, String helpText, String helpUrl) {
            this(apiName, label, t_action, t_value, helpText);
            this.helpUrl = helpUrl;
        }
    }
}