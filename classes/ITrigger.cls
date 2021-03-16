/*
This pattern involves delegating work from the trigger to a structured Trigger Handler class. 
Each object will generally have one trigger handler and the trigger will specify the handler to use.
The trigger itself has almost no code in it. 
We make use of a Factory class to instantiate the appropriate trigger handler. 
Whenever we create a new trigger all we need to do is create a new handler class and 
add a line of code to the trigger itself to delegate the work to the trigger factory. 
The trigger factory takes care of instantiating the handler and calling the handler methods in the right order.

We start by defining an Interface that provides the template for our trigger handlers. 
This interface contains the method signatures each handler must implement. See below:


*/
 /*
 * Interface containing methods Trigger Handlers must implement to enforce best practice
 * and bulkification of triggers.
 */
public interface ITrigger
{
    /**
     * bulkBefore
     *
     * This method is called prior to execution of a BEFORE trigger. Use this to cache
     * any data required into maps prior execution of the trigger.
     */
    void bulkBefore();
 
    /**
     * bulkAfter
     *
     * This method is called prior to execution of an AFTER trigger. Use this to cache
     * any data required into maps prior execution of the trigger.
     */
    void bulkAfter();
 
    /**
     * beforeInsert
     *
     * This method is called iteratively for each record to be inserted during a BEFORE
     * trigger. Never execute any SOQL/SOSL etc in this and other iterative methods.
     */
    void beforeInsert(SObject so);
 
    /**
     * beforeUpdate
     *
     * This method is called iteratively for each record to be updated during a BEFORE
     * trigger.
     */
    void beforeUpdate(SObject oldSo, SObject so);
 
    /**
     * beforeDelete
     *
     * This method is called iteratively for each record to be deleted during a BEFORE
     * trigger.
     */
    void beforeDelete(SObject so);
 
    /**
     * afterInsert
     *
     * This method is called iteratively for each record inserted during an AFTER
     * trigger. Always put field validation in the 'After' methods in case another trigger
     * has modified any values. The record is 'read only' by this point.
     */
    void afterInsert(SObject so);
 
    /**
     * afterUpdate
     *
     * This method is called iteratively for each record updated during an AFTER
     * trigger.
     */
    void afterUpdate(SObject oldSo, SObject so);
 
    /**
     * afterDelete
     *
     * This method is called iteratively for each record deleted during an AFTER
     * trigger.
     */
    void afterDelete(SObject so);

     /**
     * afterUnDelete
     *
     * This method is called iteratively for each record undeleted during an AFTER
     * trigger.
     */
    void afterUndelete(SObject so);
 
 
    /**
     * andFinally
     *
     * This method is called once all records have been processed by the trigger. Use this
     * method to accomplish any final operations such as creation or updates of other records.
     */
    void andFinally();
}