trigger NotificationsParser on Copado_Notification__c (before insert, before update) {
    for(Copado_Notification__c c : Trigger.New) {

        // do not overwrite if the message did not change ( meaning it was manually edited )
        if(Trigger.isUpdate && Trigger.oldMap.get(c.Id)!=null && Trigger.oldMap.get(c.Id).Message__c==c.Message__c) {
            System.debug('###NotificationsParser skip: '+c);
            continue;
        }

        if(String.isEmpty(c.Message__c))
            continue;

        try{
            Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(c.Message__c);
            String status = '';

            if(m.containsKey('status'))
                status = (String)m.get('status');
            c.status__c = status;

            if(m.containsKey('isFinished'))
                c.isFinished__c = c.isFinished__c || (Boolean)m.get('isFinished');
            else if(m.containsKey('status'))
                c.isFinished__c = c.isFinished__c || status=='done' || status=='Succeeded' || status=='failed'||status.startsWith('Failed');

            if(m.containsKey('matchingKeysString'))
                c.Matching_Key__c = (String)m.get('matchingKeysString');

            c.isSuccess__c = status=='Succeeded';
            if(m.containsKey('isSuccess'))
                c.isSuccess__c = (Boolean)m.get('isSuccess');

            if(String.isBlank(c.Matching_Key__c))
                c.Matching_Key__c = ''+c.Type__c+'-'+c.ParentId__c;

            System.debug('###NotificationsParser: '+c+' --- '+m);
        }catch(Exception e) {
            System.debug('there was an error when parsing Message: '+e);
        }
    }
}