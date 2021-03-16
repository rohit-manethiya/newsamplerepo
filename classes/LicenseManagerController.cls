public with sharing class LicenseManagerController {
    public static String copadoURL = Settings.server_url;
    public Integer copadoLicensesAvailable { get; set; }
    public Integer ccmLicensesAvailable { get; set; }
    public Integer cstLicensesAvailable { get; set; }
    public Integer cadLicensesAvailable { get; set; } //DP Licencias Disponibles
    public Integer cchLicensesAvailable { get; set; }
    public Integer addLicensesAvailable { get; set; }
    public Integer cbmBranchesAvailable { get; set; }
    public Integer copadoLicensesUsed { get; set; }
    public Integer ccmLicensesUsed { get; set; }
    public Integer cadLicensesUsed { get; set; } //DP Licencias Utilizadas
    public Integer cstLicensesUsed { get; set; }
    public Integer cchLicensesUsed { get; set; }
    public Integer cbmLicensesUsed { get; set; }
    public Integer addLicensesUsed { get; set; }
    public Boolean enableMultiLicenses { get; set; }
    public List<LicenseManager> copadoUsage { get; set; }
    public List<LicenseManager> ccmUsage { get; set; }
    public List<LicenseManager> cstUsage { get; set; }
    public List<LicenseManager> cadUsage { get; set; } //DP Lista de License Manager con el Usage
    public List<LicenseManager> cchUsage { get; set; }
    public List<LicenseManager> addUsage { get; set; }
    public Map<Id, Copado_License__c> licenseMap { get; set; }
    public Boolean fieldDisableFlag { get; set; }
    public User dummyUser { get; set; } //this is used for the user lookup
    public Boolean assignCopado { get; set; }
    public Boolean assignCCM { get; set; }
    public Boolean assignCST { get; set; }
    public Boolean assignCAD { get; set; } //DP
    public Boolean assignCCH { get; set; }
    public Boolean assignADD { get; set; }

    public static final String copadoLicenseLimitReached = Label.COPADO_LICENSE_LIMIT_REACHED;
    public static final String ccmLicenseLimitReached = Label.CCM_LICENSE_LIMIT_REACHED;
    public static final String cstLicenseLimitReached = Label.CST_LICENSE_LIMIT_REACHED;
    public static final String cadLicenseLimitReached = Label.CAD_LICENSE_LIMIT_REACHED;//DP Copado Agile Delivery
    public static final String cchLicenseLimitReached = Label.CCH_LICENSE_LIMIT_REACHED;
    public static final String addLicenseLimitReached = Label.ADD_LICENSE_LIMIT_REACHED;

    public LicenseManagerController() {
        //US-0001524 features are now handled by FMA/LMO standard features. No need to callout the backend.
        fieldDisableFlag = false;
        getLicenses();
        dummyUser = new User();
        if(!Schema.SObjectType.User.isAccessible()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Schema.SObjectType.User.label + ': ' + Label.Insufficient_Access_Rights));
        }
    }

    //RECOUNT NEW LICENSES USED ON ORG
    public void getLicenses() {
        copadoLicensesAvailable = FeatureManagement.checkPackageIntegerValue('EE_Licenses_Enabled');
        ccmLicensesAvailable = FeatureManagement.checkPackageIntegerValue('CCM_Licenses_Enabled');
        cstLicensesAvailable = FeatureManagement.checkPackageIntegerValue('CST_Licenses_Enabled');
        cadLicensesAvailable = FeatureManagement.checkPackageIntegerValue('CAD_Licenses_Enabled');
        cchLicensesAvailable = FeatureManagement.checkPackageIntegerValue('CCH_Licenses_Enabled');
        cbmBranchesAvailable = FeatureManagement.checkPackageIntegerValue('CBM_Branches');
        addLicensesAvailable = FeatureManagement.checkPackageIntegerValue('ADD_Licenses_Enabled');

        enableMultiLicenses = copadoLicensesAvailable > 0 && (cadLicensesAvailable > 0 || ccmLicensesAvailable > 0 || cstLicensesAvailable > 0 || cchLicensesAvailable > 0);

        copadoLicensesUsed = 0;
        ccmLicensesUsed = 0;
        cstLicensesUsed = 0;
        cadLicensesUsed = 0;
        cchLicensesUsed = 0;
        addLicensesUsed = 0;
        List<Copado_License__c> licenses = new List<Copado_License__c>();
        licenseMap = new Map<Id, Copado_License__c>();
        copadoUsage = new List<LicenseManager>();
        ccmUsage = new List<LicenseManager>();
        cstUsage = new List<LicenseManager>();
        cadUsage = new List<LicenseManager>();
        cchUsage = new List<LicenseManager>();
        addUsage = new List<LicenseManager>();
        if(Schema.SObjectType.Copado_License__c.isQueryable() && Schema.SObjectType.Copado_License__c.isAccessible()) {
            licenses = [SELECT Id, SetupOwnerId, SetupOwner.Name, Enable_CCM__c, Enable_CAD__c, Enable_CST__c, Enable_Copado__c, Enable_CCH__c, Enable_ADD__c FROM Copado_License__c ORDER BY SetupOwner.Name];
            if(!licenses.isEmpty()) {
                for(Copado_License__c l : licenses) {
                    licenseMap.put(l.SetupOwnerId, l);
                    if(l.Enable_Copado__c) {
                        copadoUsage.add(new LicenseManager(l, 'copado', this));
                        copadoLicensesUsed++;
                    }
                    if(l.Enable_CCM__c) {
                        ccmUsage.add(new LicenseManager(l, 'ccm', this));
                        ccmLicensesUsed++;
                    }
                    if(l.Enable_CST__c) {
                        cstUsage.add(new LicenseManager(l, 'cst', this));
                        cstLicensesUsed++;
                    }
                    if(l.Enable_CAD__c) {
                        cadUsage.add(new LicenseManager(l, 'cad', this)); //DP**
                        cadLicensesUsed++;
                    }
                    if(l.Enable_CCH__c) {
                        cchUsage.add(new LicenseManager(l, 'cch', this));
                        cchLicensesUsed++;
                    }
                    if(l.Enable_ADD__c) {
                        addUsage.add(new LicenseManager(l, 'add', this));
                        addLicensesUsed++;
                    }
                }
            }
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Schema.SObjectType.Copado_License__c.getName() + ': ' + Label.Insufficient_Access_Rights));
            return;
        }

        if(Schema.SObjectType.Deployment_Flow_Step__c.isQueryable() && Schema.SObjectType.Deployment_Flow_Step__c.isAccessible()) {
            cbmLicensesUsed = [
                    SELECT COUNT()
                    FROM Deployment_Flow_Step__c
                    WHERE
                    Deployment_Flow__r.Active__c = TRUE AND
                    (NOT Source_Environment__r.Type__c LIKE 'Scratch Org%') AND
                    Deployment_Flow__r.Main_Branch__c != NULL AND
                    Deployment_Flow__r.Git_Repository__c != NULL AND
                    Branch__c != NULL
            ];
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Schema.SObjectType.Deployment_Flow_Step__c.getName() + ': ' + Label.Insufficient_Access_Rights));
            return;
        }
        //If the user has no permissions to edit users, an error is shown. This method has to check the controller is called from a non VF page.
        Boolean noUserPermissions = !Schema.SObjectType.User.fields.ManagerId.isUpdateable() && (ApexPages.currentPage() != null && ApexPages.currentPage().getUrl() != null && ApexPages.currentPage().getUrl().toLowerCase().contains('licensemanager'));
        if(noUserPermissions) {
            fieldDisableFlag = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.INSUFFICIENT_LICENSE_ACCESS));
            return;
        }
    }
    /*
    This method will return true if the license count is exceeded.
    False == Everything ok.
    */
    public Boolean licenseCountExceeded(String type) {
        if(String.isBlank(type)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.InvalidLicenseType));
            return true;
        }
        if(type.equalsIgnoreCase('copado')) {
            return (copadoLicensesUsed + 1) > copadoLicensesAvailable;
        }
        if(type.equalsIgnoreCase('ccm')) {
            return (ccmLicensesUsed + 1) > ccmLicensesAvailable;
        }
        if(type.equalsIgnoreCase('cst')) {
            return (cstLicensesUsed + 1) > cstLicensesAvailable;
        }
        if(type.equalsIgnoreCase('cad')) {
            return (cadLicensesUsed + 1) > cadLicensesAvailable;
        }
        if(type.equalsIgnoreCase('cch')) {
            return (cchLicensesUsed + 1) > cchLicensesAvailable;
        }
        if(type.equalsIgnoreCase('add')) {
            return (addLicensesUsed + 1) > addLicensesAvailable;
        }
        return true;
    }
    /*
    Take the user from the dummyUser object and assign them the relevant license(s)
    */
    public void addUser() {
        if(dummyUser.ManagerId == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.MUST_SELECT_USER));
            return;
        }
        try {
            Boolean licenseLimitReached = false;
            if(licenseMap.keySet().contains(dummyUser.ManagerId)) {
                Copado_License__c license = licenseMap.get(dummyUser.ManagerId);
                if(!license.Enable_Copado__c && assignCopado && licenseCountExceeded('copado')) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, copadoLicenseLimitReached));
                    licenseLimitReached = true;
                }
                if(!license.Enable_CCM__c && assignCCM && licenseCountExceeded('ccm')) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, ccmLicenseLimitReached));
                    licenseLimitReached = true;
                }
                if(!license.Enable_CST__c && assignCST && licenseCountExceeded('cst')) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, cstLicenseLimitReached));
                    licenseLimitReached = true;
                }
                if(!license.Enable_CAD__c && assignCAD && licenseCountExceeded('cad')) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, cadLicenseLimitReached));
                    licenseLimitReached = true;
                }
                if(!license.Enable_CCH__c && assignCCH && licenseCountExceeded('cch')) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, cchLicenseLimitReached));
                    licenseLimitReached = true;
                }
                if(!license.Enable_ADD__c && assignADD && licenseCountExceeded('add')) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, cchLicenseLimitReached));
                    licenseLimitReached = true;
                }
                if(licenseLimitReached) {
                    return;
                }
                license.Enable_Copado__c = assignCopado;
                license.Enable_CCM__c = assignCCM;
                license.Enable_CST__c = assignCST;
                license.Enable_CAD__c = assignCAD;
                license.Enable_CCH__c = assignCCH;//ERROR
                license.Enable_ADD__c = assignADD;
                update license;
            } else {
                if(assignCopado && licenseCountExceeded('copado')) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, copadoLicenseLimitReached));
                    licenseLimitReached = true;
                }
                if(assignCCM && licenseCountExceeded('ccm')) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, ccmLicenseLimitReached));
                    licenseLimitReached = true;
                }
                if(assignCST && licenseCountExceeded('cst')) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, cstLicenseLimitReached));
                    licenseLimitReached = true;
                }
                if(assignCAD && licenseCountExceeded('cad')) { //***DP**
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, cadLicenseLimitReached));
                    licenseLimitReached = true;
                }
                if(assignCCH && licenseCountExceeded('cch')) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, cchLicenseLimitReached));
                    licenseLimitReached = true;
                }
                if(assignADD && licenseCountExceeded('add')) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, addLicenseLimitReached));
                    licenseLimitReached = true;
                }
                if(licenseLimitReached) {
                    return;
                }
                Copado_License__c license = new Copado_License__c();
                license.Enable_Copado__c = assignCopado;
                license.Enable_CCM__c = assignCCM;
                license.Enable_CST__c = assignCST;
                license.Enable_CAD__c = assignCAD;
                license.Enable_CCH__c = assignCCH;
                license.Enable_ADD__c = assignADD;
                license.SetupOwnerId = dummyUser.ManagerId;
                insert license;
            }
            dummyUser = new User();
            assignCopado = false;
            assignCCM = false;
            assignCST = false;
            assignCAD = false;//**DP**
            assignCCH = false;
            assignADD = false;
            getLicenses();
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.LICENSE_UPSERT_SUCCESSFUL));
        } catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, '' + e.getMessage()));
        }
    }

    // used this SOQL to check selected users active licenses to auto populate checkbox
    public void retrieveCopadoLicenses() {
        if(Schema.SObjectType.Copado_License__c.isQueryable() && Schema.SObjectType.Copado_License__c.isAccessible()) {
            for(Copado_License__c cl : [SELECT Id, Enable_CCM__c, Enable_CAD__c, Enable_CST__c, Enable_Copado__c, Enable_CCH__c, Enable_ADD__c FROM Copado_License__c WHERE SetupOwnerId = :dummyUser.ManagerId LIMIT 1]) {
                assignCopado = cl.Enable_Copado__c;
                assignCCM = cl.Enable_CCM__c;
                assignCST = cl.Enable_CST__c;
                assignCAD = cl.Enable_CAD__c;
                assignCCH = cl.Enable_CCH__c;
                assignADD = cl.Enable_ADD__c;
            }
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Schema.SObjectType.Copado_License__c.getName() + ': ' + Label.Insufficient_Access_Rights));
            return;
        }
    }

    public List<SelectOption> getLicenseTypes() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('StandardUserLookup', 'User'));
        options.add(new SelectOption('PartnerUserLookup', 'Partner User'));
        options.add(new SelectOption('CustomerSuccessUserLookup', 'Customer Portal User'));
        return options;
    }

    public class LicenseManager {
        public Copado_License__c license { get; set; }
        public String type { get; set; }
        LicenseManagerController outerClass;

        public LicenseManager(Copado_License__c l, String t, LicenseManagerController outerClass) {
            this.license = l;
            this.type = t;
            this.outerClass = outerClass;
        }
        public void removeAssignment() {
            try {
                if(type.equalsIgnoreCase('copado')) {
                    license.Enable_Copado__c = false;
                }
                if(type.equalsIgnoreCase('ccm')) {
                    license.Enable_CCM__c = false;
                }
                if(type.equalsIgnoreCase('cst')) {
                    license.Enable_CST__c = false;
                }
                if(type.equalsIgnoreCase('cad')) {
                    license.Enable_CAD__c = false;
                }
                if(type.equalsIgnoreCase('cch')) {
                    license.Enable_CCH__c = false;
                }
                if(type.equalsIgnoreCase('add')) {
                    license.Enable_ADD__c = false;
                }
                update license;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.LICENSE_UPSERT_SUCCESSFUL));
                outerClass.getLicenses();
            } catch(Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, '' + e.getMessage()));
            }
        }
    }
}