/**
 * Created by mertyalti on 18/05/2018.
 */

public with sharing class AuthorizationWithSharing extends AuthorizationCheck{
    public override List<SObject> executeQuery(String query) { return Database.query(query); }

    public override void databaseInsert(sObject sObj) { database.insert( sObj ); }
    public override void databaseUpdate(sObject sObj) { database.update( sObj ); }
    public override void databaseDelete(sObject sObj) { database.delete( sObj ); }
    public override void databaseUpsert(sObject sObj, Schema.SObjectField externalId) {
        if(externalId == null){
            database.upsert( sObj );
        } else {
            database.upsert( sObj, externalId);
        }
    }

    public override Database.SaveResult[] databaseInsert(sObject [] sObj, Boolean allOrNone) { return Database.insert(sObj, allOrNone); }
    public override Database.SaveResult[] databaseUpdate(sObject [] sObj, Boolean allOrNone) { return Database.update(sObj, allOrNone); }
    public override Database.DeleteResult[] databaseDelete(sObject [] sObj, Boolean allOrNone) { return Database.delete(sObj, allOrNone); }
    public override Database.UpsertResult[] databaseUpsert(sObject [] sObj, Boolean allOrNone, Schema.SObjectField externalId) {
        if(externalId == null){
            return Database.upsert(sObj, allOrNone);
        } else {
            return Database.upsert(sObj, externalId); // AllOrNone is not applicable in this scenario since Upsert with a field specification requires a concrete SObject type
        }

    }
}