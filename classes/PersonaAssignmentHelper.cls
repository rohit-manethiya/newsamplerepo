public class PersonaAssignmentHelper {
    
    public static Map<Id, List<Persona_Permission__c>> personaPermissionsMap = new Map<Id, List<Persona_Permission__c>>();
    public static Map<Id, List<User_Persona_Assignment__c>> personaAssignmentMap = new Map<Id, List<User_Persona_Assignment__c>>();
        
    public static List<PermissionSetAssignment> inserts = new List<PermissionSetAssignment>();
    public static Set<Id> deletes = new Set<Id>();
    public static Set<String> permInserts = new Set<String>();
    
    
    public static Map<Id, List<PermissionSetAssignment>> userPermissionSetAssignmentsMap = new Map<Id, List<PermissionSetAssignment>>();
    public static Map<Id, List<Id>> userPermissionSetAssignmentIdsMap = new Map<Id, List<Id>>();
    public static Map<Id, List<Id>> permissionToPersonasMap = new Map<Id, List<Id>>();
    public static Map<Id, Set<Id>> copadoPermissionToPersonasMap = new Map<Id, Set<Id>>();
    public static Map<Id, Set<Id>> copadoPermissionSets = new Map<Id, Set<Id>>();
    public static Map<String, Id> permissionSetNameMap = new Map<String, Id>();
    public static Map<Id, PermissionSet> permissionSetMap = new Map<Id, PermissionSet>();
    public static Set<Id> affectedUsers = new Set<Id>();
    public static Set<String> updateAssigned = new Set<String>();
    public static Set<String> updateRevoked = new Set<String>();
    public static List<User_Persona_Assignment__c> upaUpdates = new List<User_Persona_Assignment__c>();
    
    public static void prepareData(List<SObject> records){
        System.debug('@@ Prepare data for Persona Assignment Trigger');
        deletes = new Set<Id>();
        permInserts = new Set<String>();
        userPermissionSetAssignmentsMap = new Map<Id, List<PermissionSetAssignment>>();
        userPermissionSetAssignmentIdsMap = new Map<Id, List<Id>>();
        permissionToPersonasMap = new Map<Id, List<Id>>();
        copadoPermissionToPersonasMap = new Map<Id, Set<Id>>();
        //this is the list of permission set assignments a user should have based on copado
        copadoPermissionSets = new Map<Id, Set<Id>>();
        permissionSetNameMap = new Map<String, Id>();
        permissionSetMap = new Map<Id, PermissionSet>();
        affectedUsers = new Set<Id>();
        updateAssigned = new Set<String>();
        updateRevoked = new Set<String>();
        upaUpdates = new List<User_Persona_Assignment__c>();
        
        for(SObject so : records){
			User_Persona_Assignment__c pa = (User_Persona_Assignment__c)so;
            affectedUsers.add(pa.User__c);
		}
        createPersonaPermissionsMap();
        createPermissionSetNameMap();
        //ps assignment according to SFDC
		createUserPermissionSetAssignmentsMap();
        createPermissionToPersonasMap();
        //ps assignment according to Copado
        createCopadoPermissionSetAssignmentsMap();
    }
    private static void createPermissionSetNameMap(){
        for(PermissionSet ps : [SELECT Id, Name FROM PermissionSet WHERE profileId = null]){
            permissionSetNameMap.put(ps.Name, ps.Id);
            permissionSetMap.put(ps.Id, ps);
        }
        System.debug('2 - permissionSetNameMap: ' + permissionSetNameMap);
    }
    
    private static void createPersonaPermissionsMap(){
        for(Persona__c p : [SELECT Id, Name, (SELECT Id, Permission_Set_Name__c FROM Persona_Permissions__r) FROM Persona__c]){
            System.debug('### Persona__c: ' + p);
            System.debug('### Persona_Permissions__r: ' + p.Persona_Permissions__r);
            personaPermissionsMap.put(p.Id, p.Persona_Permissions__r);
            for(Persona_Permission__c pp : p.Persona_Permissions__r){
                System.debug('### Persona_Permission__c: ' + pp);
                system.debug('### Permission Set Name: '+pp.Permission_Set_Name__c);
                permissionSetNameMap.put(pp.Permission_Set_Name__c, null);
            }
        }
        System.debug('1 - permissionSetNameMap: ' + permissionSetNameMap);
        
        for(Persona__c p : [SELECT Id, Name, (SELECT Id, Name, User__c, Status__c FROM User_Persona_Assignments__r WHERE Status__c ='Permissions Assigned') FROM Persona__c]){
            System.debug('### 2 Persona__c: ' + p);
            System.debug('### 2 User_Persona_Assignments__r: ' + p.User_Persona_Assignments__r);
            personaAssignmentMap.put(p.Id, p.User_Persona_Assignments__r);
            for(User_Persona_Assignment__c upa : p.User_Persona_Assignments__r){
                System.debug('### User_Persona_Assignment__c: (' + upa.Name + ' ' + upa.Status__c + ') ' + upa);
                system.debug('### User: '+upa.User__c);
                if(!copadoPermissionToPersonasMap.containsKey(upa.User__c)){
                    copadoPermissionToPersonasMap.put(upa.User__c, new Set<Id>());
                }
                copadoPermissionToPersonasMap.get(upa.User__c).add(p.Id);
            }
        }
        System.debug('1 - copadoPermissionToPersonasMap: ' + copadoPermissionToPersonasMap);
    }
    private static void createUserPermissionSetAssignmentsMap(){
        for(User u : [SELECT Id, (SELECT Id, PermissionSetId FROM PermissionSetAssignments) FROM User WHERE Id IN :affectedUsers]){
            List<Id> tmp = new List<Id>();
            for(PermissionSetAssignment psa : u.PermissionSetAssignments){
                tmp.add(psa.PermissionSetId);
            }
            userPermissionSetAssignmentIdsMap.put(u.Id, tmp);
            userPermissionSetAssignmentsMap.put(u.Id, u.PermissionSetAssignments);
        }
        System.debug('userPermissionSetAssignmentsMap: ' + userPermissionSetAssignmentsMap);
    }
    private static void createCopadoPermissionSetAssignmentsMap(){
        //get a list of permission set assignment based on copado permissioner
        //this is useful to remove ps when needed.
        for(Id userId : copadoPermissionToPersonasMap.keySet()){
            Set<Id> tmp = new Set<Id>();
            if(copadoPermissionToPersonasMap.get(userId) == null){
                copadoPermissionToPersonasMap.put(userId,new Set<Id>());
            }
            for(Id personaId:copadoPermissionToPersonasMap.get(userId)){
                List<Persona_Permission__c> pps = personaPermissionsMap.get(personaId);
                if(pps!=null){
                    for(Persona_Permission__c pp:pps){
                        System.debug('Adding copado permissions for persona ' + personaId + ' and userId ' + userId);                
	                	tmp.add(permissionSetNameMap.get(pp.Permission_Set_Name__c));
                    }   
                }
                else{
                    System.debug('No permissions for for persona ' + personaId);
                }
            }
            copadoPermissionSets.put(userId, tmp);
        }
        System.debug('copadoPermissionSets = ' + copadoPermissionSets);
    }
    private static void createPermissionToPersonasMap(){
        for(Id i : personaPermissionsMap.keySet()){
            for(Persona_Permission__c pp : personaPermissionsMap.get(i)){
                Id permId = permissionSetNameMap.get(pp.Permission_Set_Name__c);
                List<Id> x = (permissionToPersonasMap.containsKey(permId))? permissionToPersonasMap.get(permId) : new List<Id>();
                x.add(i);
                permissionToPersonasMap.put(permId, x);
            }
        }
        System.debug('permissionToPersonasMap: ' + permissionToPersonasMap);
    }
        
    private static void addPermissionSetAssignmensForProcessing(Id userId, Id personaId){
        Set<Id> userPerms = convertListToSet(userPermissionSetAssignmentIdsMap.get(userId));
        updateAssigned.add(userId+'_'+personaId);
        for(Persona_Permission__c pp : personaPermissionsMap.get(personaId)){
            Id permId = permissionSetNameMap.get(pp.Permission_Set_Name__c);
            String key  = userId+'_'+permId;
            if(userId == null || permId == null){
                System.debug('Skipping Null values on userId ' + userId + ' or permId ' + permId);
                continue;
            }
            if(!userPerms.contains(permId) && !permInserts.contains(key)){
                inserts.add(new PermissionSetAssignment(AssigneeId=userId, PermissionSetId=permId));
                system.debug('Add to string list: '+ key);
                permInserts.add(key);
            }
        }
        //list of permission sets according to copado for this user
        Set<Id> copadoPerms = copadoPermissionSets.get(userId);
        if(copadoPerms == null){
            copadoPerms = new Set<Id>();
        }
        System.debug('### copado PermissionSets for userId ' + userId + ': ' + copadoPerms);
        List<PermissionSetAssignment> uperm = userPermissionSetAssignmentsMap.get(userId);
        System.debug('### real PermissionSetAssignment for userId ' + userId + ': ' + uperm);
        for(PermissionSetAssignment psa :uperm){
            String psName = permissionSetMap.get(psa.PermissionSetId)!=null?permissionSetMap.get(psa.PermissionSetId).Name:null;
            if(psName == null){
                System.debug('ignoring unknown permission set with id: ' + psa.PermissionSetId);
                continue;
            }
            System.debug('###  checking if ' + psa.PermissionSetId + ' ' + psName+ ' is included in ' + copadoPerms);
            // !userPerms.contains(psa.PermissionSetId) is added by Ferhat to fix the Persona Permission issue fix. US-0001364
            if(!copadoPerms.contains(psa.PermissionSetId) && !userPerms.contains(psa.PermissionSetId)){
                //TODO this is not working
                //fails with fata error message saying ps is assigned to a profile, which it isn't
                System.debug('permission out of sync with copado. removing ps: ' + psa.PermissionSetId+ ' ' + psName);
                deletes.add(psa.Id); //don't uncomment this.
            }
        }
        
    }
    private static void removePermissionSetAssignmentsForProcessing(Id userId, Id personaId){
        updateRevoked.add(userId+'_'+personaId);
        for(Persona_Permission__c pp : personaPermissionsMap.get(personaId)){
            Id permId = permissionSetNameMap.get(pp.Permission_Set_Name__c);
            system.debug('Processing removal: '+pp.Permission_Set_Name__c+'  '+permId);
            system.debug('permissionToPersonasMap: '+permissionToPersonasMap+ '!! '+permissionToPersonasMap.get(permId));
            if( permissionToPersonasMap.containsKey(permId) && permissionToPersonasMap.get(permId).size()==1 ){
                for(PermissionSetAssignment psa : userPermissionSetAssignmentsMap.get(userId)){
                    if(psa.PermissionSetId == permId)deletes.add(psa.Id);
                }
            }
        }
    }
    
    
    public static void processAssignment(User_Persona_Assignment__c oldUpa, User_Persona_Assignment__c newUpa){
        //permanent apply now
        if(oldUpa.Status__c!='Approved' && newUpa.Status__c=='Approved' && newUpa.Type__c=='Permanent'){
            System.debug('Assign Permanent Permission now: ' + newUpa);
            addPermissionSetAssignmensForProcessing(newUpa.User__c, newUpa.Persona__c);
        }
        if(oldUpa.Status__c!='Rejected' && newUpa.Status__c=='Rejected' && newUpa.Type__c=='Permanent'){
           System.debug('Revoke Permanent Permission now: ' + newUpa);
            removePermissionSetAssignmentsForProcessing(newUpa.User__c, newUpa.Persona__c);
        }
        //temporary apply now
        if(newUpa.Status__c=='Approved' && newUpa.Type__c=='Temporary' && newUpa.Apply_Schedule__c && !oldUpa.Apply_Schedule__c){
            System.debug('Assign Temporary Permission now: ' + newUpa);
            addPermissionSetAssignmensForProcessing(newUpa.User__c, newUpa.Persona__c);
        }
        if(newUpa.Status__c=='Rejected' && newUpa.Type__c=='Temporary' && newUpa.Apply_Schedule__c && !oldUpa.Apply_Schedule__c){
           System.debug('Revoke Temporary Permission now: ' + newUpa);
            removePermissionSetAssignmentsForProcessing(newUpa.User__c, newUpa.Persona__c);
        }
        //temporary schedule for future
        if(oldUpa.Status__c!='Approved' && newUpa.Status__c=='Approved' && newUpa.Type__c=='Temporary' && !newUpa.Apply_Schedule__c){
            System.debug('Schedule Temporary Permission Assignment: ' + newUpa);
            schedulePermission(newUpa);
        }
    }
    private static String getCron(DateTime dt){
        //'0 0 0 3 9 ? 2022'
        return dt.second()+' '+dt.minute() + ' ' + dt.hour() + ' ' + dt.day() + ' ' + dt.month() + ' ? ' + dt.year();
    }
    private static void schedulePermission(User_Persona_Assignment__c upa){
        User_Persona_Assignment__c futureUpa = new User_Persona_Assignment__c(Id=upa.Id);
        String startCron = getCron(upa.Start_Time__c);
        Integer rand  = Utilities.randomInteger(1000, 99999);
        String startName = 'Start: '+upa.Name + ' - ' + rand;
        String endCron = getCron(upa.End_Time__c);
        String endName = 'End: '+upa.Name + ' - ' + rand;
        System.debug('Scheduling UPA ID: ' + upa.Id);
        System.debug('Scheduling UPA: ' + upa);
        System.debug('Scheduling Future UPA: ' + futureUpa);
        System.debug('Scheduling: ' + startName);
        System.debug('Scheduling: ' + endName);
        futureUpa.Start_Schedule_ID__c = System.schedule(startName, startCron, new PermissionSchedulable(upa.Id,'Approved'));
        futureUpa.End_Schedule_ID__c = System.schedule(endName, endCron, new PermissionSchedulable(upa.Id,'Rejected'));
        upaUpdates.add(futureUpa);
    }
    
    //Converts a list of IDs to a Set of IDs
    private static Set<Id> convertListToSet(List<Id> ids){
        Set<Id> s = new Set<Id>();
        for(Id i : ids){ s.add(i); }
        return s;
    }

    public static void doFutureProcessing(){
        if(System.isFuture()){
            System.debug('@@ skipping future call');
            return;
        }
        system.debug('### doFutureProcessing - permInserts: '+permInserts);
        system.debug('### doFutureProcessing - deletes: '+deletes);
        List<PermissionSetAssignment> ins = new List<PermissionSetAssignment>();
        Set<Id> userIds = new Set<Id>();
        for(String str : permInserts){
            String[] s = str.split('_');
            String userId = s[0];
            userIds.add(userId);
        }
        Set<String> existingPerms = new Set<String>();
        for(PermissionSetAssignment psa : [SELECT AssigneeId, PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId IN :userIds]){
            existingPerms.add(psa.AssigneeId + '_' + psa.PermissionSetId);
        }
        
        for(String str : permInserts){
            System.debug('processing item: ' + str);
            String[] s = str.split('_');
            if(!existingPerms.contains(str)){
                if(s[0]==null || s[1]==null){
                    continue;
                }
                ins.add(new PermissionSetAssignment(AssigneeId=s[0], PermissionSetId=s[1]));
                existingPerms.add(str);
            }
        }
        system.debug('### insert: '+ins);
        //now invoke at future the creation of the permission set assignments
        if(ins.size()>0){
        	doInserts(JSON.serialize(ins));    
        }
        // now invoke at future the update of the UPA to confirm the assignment.
        if(updateAssigned.size()>0){
            updateStatusAssigned(updateAssigned);
        }
        system.debug('### delete: '+deletes);
        List<PermissionSetAssignment> psas = [SELECT Id, AssigneeId FROM PermissionSetAssignment WHERE Id IN :deletes];
        //now invoke at future the deletion of the permission set assignments.
        if(psas.size()>0){
         	doDeletions(JSON.serialize(psas));   
        }
        // now invoke at future the update of the UPA to confirm the revokal.
        if(updateRevoked.size()>0){
            updateStatusRevoked(updateRevoked);
        }
        //now invoke at future the update of the UPA with schedule jobs ids if any.
        if(upaUpdates.size()>0){
        	doUpdates(JSON.serialize(upaUpdates));    
        }
    } 
    public static void setDefaultValues(User_Persona_Assignment__c upa){
        upa.External_Id__c = upa.User__c + '_' + upa.Persona__c;
    }
    @Future
    public static void doInserts(String str){
        System.debug('Do insert JSON: ' + str);
        List<PermissionSetAssignment> ins = (List<PermissionSetAssignment>)JSON.deserialize(str, List<PermissionSetAssignment>.class);
        System.debug('Do insert List: ' + ins);
        Utilities.Secure_DML(ins, Utilities.DML_Action.INS, schema.Sobjecttype.PermissionSetAssignment);
    }
    @Future
    public static void doDeletions(String str){
        System.debug('Do deletions JSON: ' + str);
        List<PermissionSetAssignment> dels = (List<PermissionSetAssignment>)JSON.deserialize(str, List<PermissionSetAssignment>.class);
        System.debug('Do deletions List: ' + dels);
        Utilities.Secure_DML(dels, Utilities.DML_Action.DEL, schema.Sobjecttype.PermissionSetAssignment);
    }
    @Future
    public static void updateStatusAssigned(Set<String> externalIds){
        System.debug('Update Assigned: ' + externalIds);
        List<User_Persona_Assignment__c> upas = new List<User_Persona_Assignment__c>();
        for (String externalId :externalIds){
            upas.add(new User_Persona_Assignment__c(External_Id__c = externalId, Status__c='Permissions Assigned', Apply_Schedule__c =false));
        }
        Utilities.Secure_DML(upas, Utilities.DML_Action.UPS, schema.Sobjecttype.User_Persona_Assignment__c, schema.sObjectType.User_Persona_Assignment__c.fields.External_Id__c);
    }
    @Future
    public static void updateStatusRevoked(Set<String> externalIds){
        System.debug('Update Revoked: ' + externalIds);
        List<User_Persona_Assignment__c> upas = new List<User_Persona_Assignment__c>();
        for (String externalId :externalIds){
            upas.add(new User_Persona_Assignment__c(External_Id__c = externalId, Status__c='Permissions Revoked', Apply_Schedule__c =false));
        }
        Utilities.Secure_DML(upas, Utilities.DML_Action.UPS, schema.Sobjecttype.User_Persona_Assignment__c, schema.sObjectType.User_Persona_Assignment__c.fields.External_Id__c);
    }
    @Future
    public static void doUpdates(String str){
        System.debug('Do updates JSON: ' + str);
        List<User_Persona_Assignment__c> upas = (List<User_Persona_Assignment__c>)JSON.deserialize(str, List<User_Persona_Assignment__c>.class);
        System.debug('Do update List: ' + upas);
        Utilities.Secure_DML(upas, Utilities.DML_Action.UPD, schema.Sobjecttype.User_Persona_Assignment__c);
    }
}