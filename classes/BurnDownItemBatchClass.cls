global with sharing class BurnDownItemBatchClass implements Database.Batchable<SObject> {

    // The batch job starts
    global Database.QueryLocator start(Database.BatchableContext bc){
        System.debug('**f**start ');
        Date currentDate = System.today();
        String namespace = [SELECT COUNT() FROM ApexClass WHERE Name = 'CopadoSetupController' AND NamespacePrefix = 'copado'] == 1 ? 'copado__' : '';
        String soql = 'SELECT Id, Name, '
                + namespace + 'Start_Date__c, '
                + namespace + 'End_Date__c FROM '
                + namespace + 'Sprint__c WHERE '
                + namespace + 'End_Date__c <= :currentDate OR ( '
                + namespace + 'Start_Date__c <= :currentDate AND '
                + namespace + 'End_Date__c >= :currentDate)';
        return Database.getQueryLocator(soql);
    }

    // The batch job executes and operates on one batch of records
    global void execute(Database.BatchableContext bc, List<Sprint__c> scope){
        System.debug('**f**execute ');
        List<Burndown_Item__c> bdiList = new List<Burndown_Item__c>();
        List<Burndown_Item__c> bdiDeleteList = new List<Burndown_Item__c>();
        Date currentDate = System.today();
        Map<Id,Sprint__c> inProgressSprintMap = new Map<Id,Sprint__c>();
        Map<Id,Sprint__c> previousSprintMap = new Map<Id,Sprint__c>();
        Map<Sprint__c,Integer> totalDaysMap = new Map<Sprint__c,Integer>();
        Map<Id,Integer> passedDaysMap = new Map<Id,Integer>();
        Map<Id,Date> sprintStartDateMap = new Map<Id,Date>();
        Map<Id,Date> sprintEndDateMap = new Map<Id,Date>();
        Map<Id,Integer> sprintDurationMap = new Map<Id,Integer>();

        for(Sprint__c sobj : scope) {
            Integer totalDays = 0;
            Integer passedDays = 0;
            Date currentSprintStartDate = System.today();
            System.debug('**f**currentDate ' + currentDate + ' **f**sobj.Start_Date__c : ' + sobj.Start_Date__c + ' **f**sobj.End_Date__c : ' + sobj.End_Date__c);
            if (sobj.Start_Date__c != null && sobj.End_Date__c != null) {
                if (sobj.Start_Date__c <= currentDate && sobj.End_Date__c >= currentDate) {
                    // current sprint process.
                    inProgressSprintMap.put(sobj.Id,sobj);
                    currentSprintStartDate = sobj.Start_Date__c;
                    sprintStartDateMap.put(sobj.Id,currentSprintStartDate);
                    totalDays = sobj.Start_Date__c.daysBetween(sobj.End_Date__c);
                    totalDaysMap.put(sobj,totalDays);
                    passedDays = sobj.Start_Date__c.daysBetween(currentDate);
                    passedDaysMap.put(sobj.Id,passedDays);
                } else if (sobj.End_Date__c < currentDate) {
                    // previous sprint process. Attachment will be created and if there is attachment already nothing will happen.
                    previousSprintMap.put(sobj.Id,sobj);
                }
                sprintEndDateMap.put(sobj.Id,sobj.End_Date__c);
            Integer totalDuration = sobj.Start_Date__c.daysBetween(sobj.End_Date__c);
            sprintDurationMap.put(sobj.Id,totalDuration);
        }
        }
        System.debug('**f**inProgressSprintMap ' + inProgressSprintMap);
        System.debug('**f**previousSprintMap ' + previousSprintMap);

        if(!inProgressSprintMap.isEmpty()){
            //New ability to customize the calculation of actual velocity based on custom metadata
            Set<String> actualVelocityStatus = new Set<String>();
            for(Copado_Setting__mdt cs : [SELECT Id, Text_Field__c FROM Copado_Setting__mdt WHERE DeveloperName = 'Actual_Velocity_Statuses' LIMIT 1]){
                if(String.isNotBlank(cs.Text_Field__c)){
                    for(String str : cs.Text_Field__c.split(',')){
                        str = str.trim();
                        actualVelocityStatus.add(str);
                    }
                }else{
                    actualVelocityStatus.add('Completed');
                }
            }

            List<User_Story__c> usList = new List<User_Story__c>();
            if(Schema.SObjectType.User_Story__c.isQueryable() && Schema.SObjectType.User_Story__c.isAccessible()){
                usList = [SELECT Story_Points_SFDC__c, Status__c, Sprint__c FROM User_Story__c WHERE Sprint__c = :inProgressSprintMap.keySet()];
            }

            // Calculate total story points
            Map<Id,Decimal> totalStoryPointMap = new Map<Id,Decimal>();
            Map<Id,Decimal> actualStoryPointMap = new Map<Id,Decimal>();
            if(!usList.isEmpty()){
                for(User_Story__c us : usList){
                    if(actualVelocityStatus.contains(us.Status__c)){
                        if(!actualStoryPointMap.containsKey(us.Sprint__c)){
                            actualStoryPointMap.put(us.Sprint__c, us.Story_Points_SFDC__c != null ? us.Story_Points_SFDC__c : 0);
                        } else{
                            Decimal existingActualNumber = actualStoryPointMap.get(us.Sprint__c);
                            actualStoryPointMap.put(us.Sprint__c, existingActualNumber + (us.Story_Points_SFDC__c != null ? us.Story_Points_SFDC__c : 0));
                        }
                    }
                    if(us.Story_Points_SFDC__c != null){
                        if(!totalStoryPointMap.containsKey(us.Sprint__c)){
                            totalStoryPointMap.put(us.Sprint__c, us.Story_Points_SFDC__c != null ? us.Story_Points_SFDC__c : 0);
                        } else{
                            Decimal existingTotalNumber = totalStoryPointMap.get(us.Sprint__c);
                            totalStoryPointMap.put(us.Sprint__c, existingTotalNumber + (us.Story_Points_SFDC__c != null ? us.Story_Points_SFDC__c : 0));
                        }
                    }
                }
            }

            Map<String,Decimal> decreaseStoryPointByMap = new Map<String,Decimal>();
            for(Sprint__c spr : totalDaysMap.keySet()){
                Decimal decreaseStoryPointBy = totalStoryPointMap.containsKey(spr.Id) && totalStoryPointMap.get(spr.Id) != 0 && totalDaysMap.get(spr) != 0 ? totalStoryPointMap.get(spr.Id) / totalDaysMap.get(spr) : 0;
                decreaseStoryPointByMap.put(spr.Id, decreaseStoryPointBy);
            }

            List<Burndown_Item__c> dwiList = new List<Burndown_Item__c>();
            if(Schema.SObjectType.Burndown_Item__c.isQueryable() && Schema.SObjectType.Burndown_Item__c.isAccessible()){
                dwiList = [SELECT Id,Date__c,Sprint__c,Expected_Story_Point__c FROM Burndown_Item__c WHERE Sprint__c = :inProgressSprintMap.keySet()];
            }

            if(dwiList.isEmpty()){
                for(Id sprId : inProgressSprintMap.keySet()){
                    Integer totalDays = totalDaysMap.get(inProgressSprintMap.get(sprId));
                    for(Integer i=0; i<(totalDays+1); i++){
                        Date firstDate = sprintStartDateMap.get(sprId).addDays(i);
                        Burndown_Item__c bdi = new Burndown_Item__c();
                        if(!Schema.SObjectType.Burndown_Item__c.fields.Sprint__c.isCreateable() || !Schema.SObjectType.Burndown_Item__c.fields.Date__c.isCreateable() || !Schema.SObjectType.Burndown_Item__c.fields.Expected_Story_Point__c.isCreateable() || !Schema.SObjectType.Burndown_Item__c.fields.Total_Story_Point__c.isCreateable()){
                            return;
                        }
                        bdi.Sprint__c = sprId;
                        bdi.Date__c = firstDate;
                        bdi.Expected_Story_Point__c = (totalStoryPointMap.containsKey(sprId) && decreaseStoryPointByMap.containsKey(sprId)) ? (totalStoryPointMap.get(sprId) - (decreaseStoryPointByMap.get(sprId) * i)) : 0;
                        Decimal actualpoint = actualStoryPointMap.containsKey(sprId) ? actualStoryPointMap.get(sprId) : 0;
                        bdi.Total_Story_Point__c = (i == 0 && totalStoryPointMap.containsKey(sprId) )? totalStoryPointMap.get(sprId) - actualpoint : 0;
                        bdiList.add(bdi);
                    }
                }
            } else{
                Set<String> dwiIdSet = new Set<String>();
                Map<Id,Integer> bdiNumberMap = new Map<Id,Integer>();
                for(Burndown_Item__c bdi : dwiList){
                    dwiIdSet.add(bdi.Sprint__c);
                    Date startDate = sprintStartDateMap.get(bdi.Sprint__c);
                    Integer passedDay = passedDaysMap.get(bdi.Sprint__c);

                    Integer dateDiff = sprintStartDateMap.get(bdi.Sprint__c).daysBetween(bdi.Date__c);
                    Decimal expectedStoryPoint = (totalStoryPointMap.containsKey(bdi.Sprint__c) && decreaseStoryPointByMap.containsKey(bdi.Sprint__c)) ?  (totalStoryPointMap.get(bdi.Sprint__c) - (decreaseStoryPointByMap.get(bdi.Sprint__c) * dateDiff)) : 0;

                    if(bdi.Date__c == startDate.addDays(passedDay)){
                        if(!Schema.SObjectType.Burndown_Item__c.fields.Total_Story_Point__c.isUpdateable() || !Schema.SObjectType.Burndown_Item__c.fields.Expected_Story_Point__c.isUpdateable()){
                            return;
                        }
                        if(bdi.Expected_Story_Point__c != expectedStoryPoint){
                            bdi.Expected_Story_Point__c = expectedStoryPoint;
                        }
                        Decimal actualpoint = actualStoryPointMap.containsKey(bdi.Sprint__c) ? actualStoryPointMap.get(bdi.Sprint__c) : 0;
                        bdi.Total_Story_Point__c = totalStoryPointMap.containsKey(bdi.Sprint__c) ? (totalStoryPointMap.get(bdi.Sprint__c) - actualpoint) : 0;
                        bdiList.add(bdi);
                    } else if(bdi.Expected_Story_Point__c != expectedStoryPoint && sprintEndDateMap.containsKey(bdi.Sprint__c) && sprintEndDateMap.get(bdi.Sprint__c) >= bdi.Date__c){
                        if(!Schema.SObjectType.Burndown_Item__c.fields.Expected_Story_Point__c.isUpdateable()){
                            return;
                        }
                        bdi.Expected_Story_Point__c = expectedStoryPoint;
                        bdiList.add(bdi);
                    } else if(sprintEndDateMap.containsKey(bdi.Sprint__c) && sprintEndDateMap.get(bdi.Sprint__c) < bdi.Date__c){
                        bdiDeleteList.add(bdi);
                    }

                    if(!bdiNumberMap.containsKey(bdi.Sprint__c)){
                        bdiNumberMap.put(bdi.Sprint__c,1);
                    } else{
                        Integer existingNumber = bdiNumberMap.get(bdi.Sprint__c);
                        bdiNumberMap.put(bdi.Sprint__c,existingNumber+1);
                    }
                }
                for(Id spr : inProgressSprintMap.keySet()){
                    if(!dwiIdSet.contains(spr)){
                        Integer totalDays = totalDaysMap.get(inProgressSprintMap.get(spr));
                        for(Integer i=0; i<(totalDays+1); i++){
                            Date firstDate = sprintStartDateMap.get(spr).addDays(i);
                            Burndown_Item__c bdi = new Burndown_Item__c();
                            if(!Schema.SObjectType.Burndown_Item__c.fields.Sprint__c.isCreateable() || !Schema.SObjectType.Burndown_Item__c.fields.Date__c.isCreateable() || !Schema.SObjectType.Burndown_Item__c.fields.Expected_Story_Point__c.isCreateable() || !Schema.SObjectType.Burndown_Item__c.fields.Total_Story_Point__c.isCreateable()){
                                return;
                            }
                            bdi.Sprint__c = spr;
                            bdi.Date__c = firstDate;
                            bdi.Expected_Story_Point__c = (totalStoryPointMap.containsKey(spr) && decreaseStoryPointByMap.containsKey(spr)) ? (totalStoryPointMap.get(spr) - (decreaseStoryPointByMap.get(spr) * i)) : 0;
                            Decimal actualpoint = actualStoryPointMap.containsKey(spr) ? actualStoryPointMap.get(spr) : 0;
                            bdi.Total_Story_Point__c = (i == 0 && totalStoryPointMap.containsKey(spr)) ? totalStoryPointMap.get(spr) - actualpoint : 0;
                            bdiList.add(bdi);
                        }
                    }

                    if(sprintDurationMap.containsKey(spr) && bdiNumberMap.containsKey(spr) && sprintDurationMap.get(spr) >= bdiNumberMap.get(spr)){
                        Integer dayDifference = sprintDurationMap.get(spr) - bdiNumberMap.get(spr);
                        Integer startDay = sprintDurationMap.get(spr) - dayDifference;

                        for(Integer i=startDay; i<(sprintDurationMap.get(spr)+1); i++){
                            Date newDate = sprintStartDateMap.get(spr).addDays(i);
                            Burndown_Item__c bdi = new Burndown_Item__c();
                            if(!Schema.SObjectType.Burndown_Item__c.fields.Sprint__c.isCreateable() || !Schema.SObjectType.Burndown_Item__c.fields.Date__c.isCreateable() || !Schema.SObjectType.Burndown_Item__c.fields.Expected_Story_Point__c.isCreateable() || !Schema.SObjectType.Burndown_Item__c.fields.Total_Story_Point__c.isCreateable()){
                                return;
                            }
                            bdi.Sprint__c = spr;
                            bdi.Date__c = newDate;
                            bdi.Expected_Story_Point__c = (totalStoryPointMap.containsKey(spr) && decreaseStoryPointByMap.containsKey(spr)) ? (totalStoryPointMap.get(spr) - (decreaseStoryPointByMap.get(spr) * i)) : 0;
                            Decimal actualpoint = actualStoryPointMap.containsKey(spr) ? actualStoryPointMap.get(spr) : 0;
                            bdi.Total_Story_Point__c = i == 0 ? totalStoryPointMap.get(spr) - actualpoint : 0;
                            bdiList.add(bdi);
                        }
                    }
                }
            }
            if(!bdiList.isEmpty() && Schema.SObjectType.Burndown_Item__c.isCreateable() && Schema.SObjectType.Burndown_Item__c.isUpdateable()){
                Utilities.Secure_DML(bdiList, Utilities.DML_Action.UPS, schema.SObjectType.Burndown_Item__c);
            }
            if(!bdiDeleteList.isEmpty() && Schema.SObjectType.Burndown_Item__c.isDeletable()){
                Utilities.Secure_DML(bdiDeleteList, Utilities.DML_Action.DEL, schema.SObjectType.Burndown_Item__c);
            }
        }

        // Checking for attachment for previous sprint
        if(!previousSprintMap.isEmpty() && Schema.SObjectType.Burndown_Item__c.isQueryable()){
            // Attachment create and delete burndown items of previous sprint
            Map<Id,List<BurndownItem>> bdiWrapperMap = new  Map<Id,List<BurndownItem>>();
            List<Burndown_Item__c> deleteBdiList = new List<Burndown_Item__c>();
            for(Burndown_Item__c bi : [SELECT Id,Date__c,Total_Story_Point__c,Expected_Story_Point__c,Sprint__c FROM Burndown_Item__c WHERE Sprint__c = :previousSprintMap.keySet()]){

                if(!bdiWrapperMap.containsKey(bi.Sprint__c)){
                    List<BurndownItem> bdiWrapperList = new List<BurndownItem>();
                    bdiWrapperList.add(new burndownItem(String.valueOf(bi.Date__c),bi.Expected_Story_Point__c,bi.Total_Story_Point__c));
                    bdiWrapperMap.put(bi.Sprint__c,bdiWrapperList);
                } else{
                    bdiWrapperMap.get(bi.Sprint__c).add(new burndownItem(String.valueOf(bi.Date__c),bi.Expected_Story_Point__c,bi.Total_Story_Point__c));
                }

                deleteBdiList.add(bi);
            }

            if(!bdiWrapperMap.isEmpty()){
                List<Attachment> attList = new List<Attachment>();
                for(Id sprId : bdiWrapperMap.keySet()){
                    Attachment att = new Attachment();
                    if(!Schema.SObjectType.Attachment.fields.Name.isCreateable() || !Schema.SObjectType.Attachment.fields.Body.isCreateable() || !Schema.SObjectType.Attachment.fields.ParentId.isCreateable()){
                        return;
                    }
                    att.Name = 'BurnDownItems';
                    att.Body = Blob.valueOf(JSON.serialize(bdiWrapperMap.get(sprId)));
                    att.ParentId = sprId;
                    attList.add(att);
                }

                if(!attList.isEmpty() && Schema.SObjectType.Attachment.isCreateable()){
                    Utilities.Secure_DML(attList, Utilities.DML_Action.INS, schema.SObjectType.Attachment);
                }

                if(!deleteBdiList.isEmpty() && Schema.SObjectType.Burndown_Item__c.isDeletable()){
                    Utilities.Secure_DML(deleteBdiList, Utilities.DML_Action.DEL, schema.SObjectType.Burndown_Item__c);
                }
            }
        }
    }

    // The batch job finishes
    global void finish(Database.BatchableContext bc){
        System.debug('**f**finish ');
    }
}