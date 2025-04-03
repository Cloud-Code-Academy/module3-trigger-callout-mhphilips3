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

        // - Filter categories that need to be synced
        List<String> categoryNames = new List<String>();
        Map<String, Id> categoryNameToIdMap = new Map<String, Id>();
        for (News_Category__c cat : newRecords){
            if(cat.Sync__c){
                categoryNames.add(cat.Name);
                categoryNameToIdMap.put(cat.Name, cat.Id);
            }
        }
        System.debug('categoryNameToIdMap: ' + categoryNameToIdMap);
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
        
        // - Filter categories that need to be synced
        List<News_Category__c> categoriesToSync = new List<News_Category__c>();
        for(News_Category__c record : newRecords){
            if(record.Sync__c && !oldMap.get(record.Id).Sync__c){
                categoriesToSync.add(record);
            }
        }

        // - Call queueable method for callouts
        if(!categoriesToSync.isEmpty()){
            syncCategoriesWithQueueable(categoriesToSync);
        }
    }
    
    /**
     * Future method to sync categories using the NewsAPI
     * Used for insert operations
     * @param categoryNameToIdMap, a map of category names to ids
     */
    @future(callout=true)
    public static void syncCategoriesWithFuture(Map<String, Id> categoryNameToIdMap) {
        
        // Create ProcessingResult instance to track state during the integration run\
        ProcessingResult result = new ProcessingResult();
        result.messageList.add('NewsAPI Sync Log, Future Path:');

        // - Make callouts to NewsAPI for each category
        System.debug('received map: ' + categoryNameToIdMap);
        Integer count = 1;
        for (String categoryName : categoryNameToIdMap.keySet()){
            result.messageList.add(count + '. Syncing \'' + categoryName + '\' category:');
            String catId = categoryNameToIdMap.get(categoryName);
            System.debug('catId: ' + catId);

            try{
                NewsAPIResponse response = NewsAPIService.getTopHeadlinesByCategory(categoryName, null, null);
                
                // If callout successful and pulls back articles, convert to Article__c records, log success message, and flag success
                if(response !=null && !response.articles.isEmpty()){
                    List<Article__c> articles = response.toSObjects(categoryNameToIdMap.get(categoryName), categoryName);
                    result.articlesToInsert.addAll(articles);
                    result.addLogSuccess('     - Retrieved ' + articles.size() + ' articles');
                    result.incrementRecordsProcessed(articles.size());
                    System.debug('received results from test: ' + articles);
                } else {
                    result.addLogError('     - No articles returned for category');
                    categoryNameToIdMap.remove(categoryName); // Remove category that did not sync properly
                    System.debug('no articles returned for category');
                }                
            } catch (Exception e) {
                result.addLogError('     - Error during callout: ' + e.getMessage());
                categoryNameToIdMap.remove(categoryName); // Remove category that did not sync properly
                System.debug('Error during callout: ' + e.getMessage());
            }

            count++;
        }

        // - Insert retrieved articles
        if(!result.articlesToInsert.isEmpty()){
            try{
                insert result.articlesToInsert;
                result.addLogSuccess('     - Inserted ' + result.articlesToInsert.size() + ' total articles.');
                System.debug ('inserted artiles');
            } catch (Exception e) {
                result.addLogError('     - Error on article insertion: ' + e.getMessage());
                System.debug('article insertion failed: ' + e.getMessage());
            }
        }

        // Finalize and insert log entry
        result.finalizeLogEntry();
        insert result.logEntry;

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
        
        // Generate runGroupId to relate multiple log records
        String runGroupId = String.valueOf(Crypto.getRandomLong());
        Integer sequence = 1;

        // - Create and enqueue NewsCategoryQueueable job for each category record (clone category first to avoid read only fail)
        for (News_Category__c cat : categoriesToSync){
            News_Category__c catClone = cat.clone(true, false, false, false);
            System.enqueueJob(new NewsCategoryQueueable(catClone, runGroupId, sequence));
            sequence += cat.Pages__c != null ? Integer.valueOf(cat.Pages__c) : 1;
        }

        /**
         * Kick off Log Consolidation Process (queueable) with the following parameters:
         * runGroupId
         * expectedCount = sequence -1
         * delayMinutes = 2 
         */
        try{
            System.enqueueJob(new LogRollupQueueable(runGroupId, sequence - 1, 2), 2);
        } catch (Exception e){
            System.debug ('error consolidating logs: ' + e.getMessage());
        }
    }

    private static void updateSyncedCategories(List<Id> categoryIds){

        List<News_Category__c> catRecordsToUpdate = new List<News_Category__c>();
        for(Id categoryId : categoryIds){
            News_Category__c newCat = new News_Category__c (
                Id = categoryId,
                Last_Synced__c = Datetime.now(),
                Sync__c = false
            );

            catRecordsToUpdate.add(newCat);
        }

        update catRecordsToUpdate;
    }    
} 