/**
 * Queueable Apex class for processing News Category records with pagination support.
 * Each job handles a single category and one page of results from the NewsAPI.
 * If additional pages are required, the job will chain itself with the next page number.
 * One Integration_Log__c record is created per page processed, tagged with a shared Run Group ID.
 */
public class NewsCategoryQueueable implements Queueable, Database.AllowsCallouts {
    private News_Category__c category; // News_Category__c record
    private String runGroupId; // Id that indicates which log records belong to the same run
    private Integer pages; // Number of pages to sync
    private Integer currentPage; // Current callout page
    private Integer pageSize; // Number of articles per page -- currently unused here, but placeholder for next step
    private Integer sequence; // Order of Integration Log records related to the same run
    
    /**
     * Constructor for initial page (Page 1).
     * @param category Full News_Category__c record to process
     * @param runGroupId Shared identifier for grouping log records across the full run
     * @param sequence Used to consolidate log records in proper order
     */
    public NewsCategoryQueueable(News_Category__c category, String runGroupId, Integer sequence) {
        // TODO: Initialize first page
        this.category = category;
        this.pages = category.Pages__c != null ? Integer.valueOf(category.Pages__c) : 1;
        this.currentPage = 1;
        this.runGroupId = runGroupId;
        this.sequence = sequence;
    }
    
    /**
     * Constructor for chaining subsequent pages.
     * @param category Full News_Category__c record to process
     * @param currentPage Page number to process (starts at 2+)
     * @param runGroupId Shared identifier for grouping log records across the full run
     * @param sequence Used to consolidate log records in proper order
     */
    public NewsCategoryQueueable(News_Category__c category, Integer currentPage, String runGroupId, Integer sequence) {
        // Initialize with specific page
        this.category = category;
        this.currentPage = currentPage;
        this.runGroupId = runGroupId;
        this.pages = category.Pages__c != null ? Integer.valueOf(category.Pages__c) : 1;
        this.sequence = sequence;
    }
    
    /**
     * Execute method for the queueable job
     * @param context The QueueableContext
     */
    public void execute(QueueableContext context) {
        // Initialize ProcessingResult wrapper for logging
        ProcessingResult result = new ProcessingResult();
        result.setRunGroupId(runGroupId);
        result.setLogSequence(sequence);
        // result.messageList[0] = result.messageList[0].replace('[Async Process]', 'Queueable Path');
        result.messageList.add('Page ' + currentPage + ' of ' + pages + ' - Syncing category: ' + category.Name);
        
        // - Call NewsAPI for the current page
        try{
            NewsAPIResponse response = NewsAPIService.getTopHeadlinesByCategory(category.Name, pageSize, currentPage);
            if(response != null && !response.articles.isEmpty()){
                // Convert response to Article__c records
                System.debug(category.Id);
                List<Article__c> articlesToInsert = response.toSObjects(category.Id, category.Name);
                result.addLogSuccess('     - Retrieved ' + articlesToInsert.size() + ' articles');

                // Insert Article__c records
                try{
                    insert articlesToInsert;
                    result.incrementRecordsProcessed(articlesToInsert.size());
                    result.addLogSuccess('     - Inserted ' + articlesToInsert.size() + ' total articles.');
                } catch (Exception e) {
                    result.addLogError('     - Error on article insertion: ' + e.getMessage());
                }
            } else {
                result.addLogError('     - No articles returned for category');
            }
        } catch (Exception e){
            result.addLogError('     - Error during callout: ' + e.getMessage());
        }

        // - Update category if last page, chain to next page if more pages exist
        if (currentPage < pages){
            System.enqueueJob(new NewsCategoryQueueable(category, currentPage + 1, runGroupId, sequence + 1));
            result.addLogSuccess('     - Queued next page (' + (currentPage +1) +')');
        } else {
            category.Last_Synced__c = System.now(); // Set Last Synced time
            category.Sync__c = false; // Reset sync flag after full run
            try {
                update category;
                result.addLogSuccess('     - Final page processed.  Updated Last_Synced__c.');
            } catch (Exception e){
                result.addLogError('     - Error updating Last_Synced__c: ' + e.getMessage());
            }
        }

        // Finalize and insert Integration Log for current queueable
        result.finalizeLogEntry();
        insert result.logEntry;
    }
} 