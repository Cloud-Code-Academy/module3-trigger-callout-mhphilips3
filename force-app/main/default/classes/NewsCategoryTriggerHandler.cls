/**
 * Handler class for NewsCategoryTrigger
 */
public with sharing class NewsCategoryTriggerHandler {
    
    /**
     * Handles after insert events for News_Category__c
     * Uses Future method for callouts when Sync__c is true
     * @param newRecords List of newly inserted News_Category__c records
     */
    public static void handleInsert(List<News_Category__c> newRecords) {
        // TODO: Implement insert handler
        // - Filter categories that need to be synced
        List<String> categoryNames = new List<String>();
        Map<String, Id> categoryNameToIdMap = new Map<String, Id>();
        for (News_Category__c cat : newRecords){
            if(cat.Sync__c){
                categoryNames.add(cat.Name);
                categoryNameToIdMap.put(cat.Name, cat.Id);
            }
        }


        // - Call future method for callouts
        if(!categoryNames.isEmpty()){
            syncCategoriesWithFuture(categoryNameToIdMap);
        }
    }
    
    /**
     * Handles after update events for News_Category__c
     * Uses Queueable Apex for callouts when Sync__c is true
     * @param newRecords List of updated News_Category__c records
     * @param oldMap Map of old record states
     */
    public static void handleUpdate(List<News_Category__c> newRecords, Map<Id, News_Category__c> oldMap) {
        // TODO: Implement update handler
        // - Filter categories that need to be synced
        // - Call queueable method for callouts
    }
    
    /**
     * Future method to sync categories using the NewsAPI
     * Used for insert operations
     * @param categoryNameToIdMap, a map of category names to ids
     */
    @future(callout=true)
    public static void syncCategoriesWithFuture(Map<String, Id> categoryNameToIdMap) {
        // TODO: Implement future method
        // Create ProcessingResult instance to track state during the integration run\
        ProcessingResult result = new ProcessingResult();
        result.messageList[0] = result.messageList[0].replace('[Async Process]', 'Future Path');

        // - Make callouts to NewsAPI for each category
        System.debug('received map: ' + categoryNameToIdMap);
        Integer count = 1;
        for (String categoryName : categoryNameToIdMap.keySet()){
            result.messageList.add(count + '. Syncing \'' + categoryName + '\' category:');

            try{
                NewsAPIResponse response = NewsAPIService.getTopHeadlinesByCategory(categoryName, null, null);
                
                // If callout successful and pulls back articles, convert to Article__c records, log success message, and flag success
                if(response !=null && !response.articles.isEmpty()){
                    List<Article__c> articles = response.toSObjects();
                    result.articlesToInsert.addAll(articles);
                    result.addLogSuccess('     - Retrieved ' + articles.size() + ' articles');
                    result.incrementRecordsProcessed(articles.size());
                } else {
                    result.addLogError('     - No articles returned for category');
                    categoryNameToIdMap.remove(categoryName); // Remove category that did not sync properly
                }                
            } catch (Exception e) {
                result.addLogError('     - Error during callout: ' + e.getMessage());
                categoryNameToIdMap.remove(categoryName); // Remove category that did not sync properly
            }

            count++;
        }

        // - Insert retrieved articles
        if(!result.articlesToInsert.isEmpty()){
            try{
                insert result.articlesToInsert;
                result.addLogSuccess('Inserted ' + result.articlesToInsert.size() + ' total articles.');
            } catch (Exception e) {
                result.addLogError('Error on article insertion: ' + e.getMessage());
            }
        }

        // Finalize and insert log entry
        result.finalizeLogEntry();

        // - Clean up by updating categories with current date
        if(!categoryNameToIdMap.isEmpty()){
            updateSyncedCategories(categoryNameToIdMap.values());
        }
    }
    
    /**
     * Queueable method to sync categories using the NewsAPI
     * Used for update operations
     * @param categoriesToSync List of News_Category__c records to sync
     */
    private static void syncCategoriesWithQueueable(List<News_Category__c> categoriesToSync) {
        // TODO: Implement queueable job enqueuing
        // Create ProcessingResult instance to track state during the integration run\
        ProcessingResult result = new ProcessingResult();
        result.messageList[0] = result.messageList[0].replace('[Async Process]', 'Queueable Path');
        // - Determine pages to sync for each category
        // - Create and enqueue NewsCategoryQueueable job for each category
    }

    private static void updateSyncedCategories(List<Id> categoryIds){

        List<News_Category__c> catRecordsToUpdate = new List<News_Category__c>();
        for(Id categoryId : categoryIds){
            News_Category__c newCat = new News_Category__c (
                Id = categoryId,
                Last_Synced__c = Datetime.now()
            );

            catRecordsToUpdate.add(newCat);
        }

        update catRecordsToUpdate;
    }    
} 