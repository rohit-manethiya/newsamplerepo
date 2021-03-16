public with sharing class PermissionSetExplorerExt {

    public static Set<String> PermSetSelected { get; set; }
    public static String PersonaId { get; set; }
    public static List<FieldPermissions> Lfls { get; set; }
    public static List<ObjectPermissions> Lols { get; set; }
    public static List<SystemPermissions> Lsup { get; set; }

    public PermissionSetExplorerExt() {

    }


    public List<SelectOption> getPersonas() {
        List<Persona__c> Lpers = [SELECT Id, Name FROM Persona__c];
        List<SelectOption> LpersonasOpt = new List<SelectOption>();

        for(Persona__c ps : Lpers) {
            LpersonasOpt.add(new SelectOption(ps.Id, ps.Name));
        }
        return LpersonasOpt;
    }

    public static void LoadPermissions() {
        PermSetSelected = new Set<String>();
        if(Schema.sObjectType.Persona_Permission__c.isQueryable() && Schema.sObjectType.Persona_Permission__c.isAccessible()) {
            for(Persona_Permission__c pp : [SELECT Permission_Set_Name__c FROM Persona_Permission__c WHERE Persona__c = :PersonaId]) {
                PermSetSelected.add(pp.Permission_Set_Name__c);
            }
        }

        Lfls = getFieldPermissions();
        Lols = getObjectPermissions();
        Lsup = getSystemPermissions();

        if(Lfls.isEmpty() && Lols.isEmpty() && Lsup.isEmpty()) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING, Label.NO_PERMISSIONS_FOUND));
        }
    }

    public static List<FieldPermissions> getFieldPermissions() {

        if(PermSetSelected != null) {
            List<FieldPermissions> LflsTmp = new List<FieldPermissions>();
            if(Schema.sObjectType.FieldPermissions.isQueryable() && Schema.sObjectType.FieldPermissions.isAccessible()) {
                LflsTmp = [
                        SELECT Field,Parent.Name,PermissionsEdit,PermissionsRead,SobjectType
                        FROM FieldPermissions
                        WHERE Parent.Name IN :PermSetSelected
                        ORDER BY SobjectType, Field
                ];
            }

            Map<String, FieldPermissions> Mfp = new Map<String, FieldPermissions>();
            for(FieldPermissions fp : LflsTmp) {

                if(Mfp.containsKey(fp.Field)) {
                    FieldPermissions fpTemp = Mfp.get(fp.Field);
                    fp.PermissionsEdit = fp.PermissionsEdit || fpTemp.PermissionsEdit;
                    fp.PermissionsRead = fp.PermissionsRead || fpTemp.PermissionsRead;
                    Mfp.put(fp.Field, fp);
                } else {
                    Mfp.put(fp.Field, fp);
                }
            }

            return Mfp.values();
        } else return new List<FieldPermissions>();
    }

    public static List<ObjectPermissions> getObjectPermissions() {

        if(PermSetSelected != null) {
            List<ObjectPermissions> LolsTmp = new List<ObjectPermissions>();
            if(Schema.sObjectType.Attachment.isQueryable() && Schema.sObjectType.Attachment.isAccessible()) {
                LolsTmp = [
                        SELECT ParentId,PermissionsCreate,PermissionsDelete,PermissionsEdit,PermissionsModifyAllRecords,PermissionsRead,PermissionsViewAllRecords,SobjectType
                        FROM ObjectPermissions
                        WHERE Parent.Name IN :PermSetSelected
                        ORDER BY SobjectType
                ];
            }
            Map<String, ObjectPermissions> Mop = new Map<String, ObjectPermissions>();
            for(ObjectPermissions op : LolsTmp) {

                if(Mop.containsKey(op.SobjectType)) {
                    ObjectPermissions opTemp = Mop.get(op.SobjectType);
                    op.PermissionsCreate = op.PermissionsCreate || opTemp.PermissionsCreate;
                    op.PermissionsDelete = op.PermissionsDelete || opTemp.PermissionsDelete;
                    op.PermissionsEdit = op.PermissionsEdit || opTemp.PermissionsEdit;
                    op.PermissionsRead = op.PermissionsRead || opTemp.PermissionsRead;
                    op.PermissionsViewAllRecords = op.PermissionsViewAllRecords || opTemp.PermissionsViewAllRecords;
                    op.PermissionsModifyAllRecords = op.PermissionsModifyAllRecords || opTemp.PermissionsModifyAllRecords;
                    Mop.put(op.SobjectType, op);
                } else {
                    Mop.put(op.SobjectType, op);
                }
            }

            return Mop.values();
        } else return new List<ObjectPermissions>();
    }

    public static List<SystemPermissions> getSystemPermissions() {

        List<PermissionSet> Lps = new List<PermissionSet>();
        Map<String, Boolean> MsystemPermissions = new Map<String, Boolean>();
        List<String> accessiblefields = new List<String>();
        List<SystemPermissions> Lsysperms = new List<SystemPermissions>();

        Map<String, String> d = Utilities.getAllFields(Label.PERMISSION_SET_SOBJECT_NAME);

        if(d != null && d.containsKey(Label.FIELDS)) {
            accessiblefields = d.get(Label.FIELDS).split(',');

            List<Id> LpsIds = new List<Id>();
            if(Schema.sObjectType.PermissionSet.isQueryable() && Schema.sObjectType.PermissionSet.isAccessible()) {
                for(PermissionSet ps : [SELECT Id FROM PermissionSet WHERE Name IN :PermSetSelected]) {
                    LpsIds.add(ps.Id);
                }
            }
            
            for(Id psId : LpsIds) {
                PermissionSet psTmp = Utilities.getPermissionSetById(psId);

                for(String field : accessiblefields) {
                    if(field.contains(Label.PERMISSION_FILTER)) {
                        if(MsystemPermissions.containsKey(field)) {
                            Boolean val = MsystemPermissions.get(field);
                            val = val || (Boolean) psTmp.get(field);
                            if(val == true) {
                                MsystemPermissions.put(field, val);
                            }
                        } else {
                            try {
                                //try catch logic is implemented to prevent issues because of beta(pilot) fields such as PermissionSetGroupId
                                if((Boolean) psTmp.get(field) == true) {
                                    MsystemPermissions.put(field, (Boolean) psTmp.get(field));
                                }
                            } catch(Exception ex) {
                                System.debug('ex.message ===> ' + ex.getMessage());
                            }
                        }
                    }
                }
            }

            for(String fieldKey : MsystemPermissions.keySet()) {
                SystemPermissions sysperm = new SystemPermissions();
                sysperm.fieldName = fieldKey;
                sysperm.enabled = MsystemPermissions.get(fieldKey);
                Lsysperms.add(sysperm);
            }

            System.debug('lsysperms::: ' + Lsysperms);
            return Lsysperms;
        } else return new List<SystemPermissions>();
    }

    public class SystemPermissions {
        public String fieldName { get; set; }
        public Boolean enabled { get; set; }
    }
}