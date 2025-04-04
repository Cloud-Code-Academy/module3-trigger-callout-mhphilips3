/**
 * Trigger for News_Category__c object to sync news from API when Sync__c field is true
 */
trigger NewsCategoryTrigger on News_Category__c (after insert, after update) {
    
    // - Call appropriate handler methods for insert and update contexts
    if (Trigger.isUpdate){
        NewsCategoryTriggerHandler.handleUpdate(Trigger.new, Trigger.oldMap);
    }

    if (Trigger.isInsert){
        NewsCategoryTriggerHandler.handleInsert(Trigger.new);
    }
} 