/**
 * Queueable class to consolidate Integration_Log__c records
 * that share a Run_Group_Id__c, once all expected logs have been created.
 * If this runs before all expected logs have been created, it will requeue, with an additional delay.
 */
public with sharing class LogRollupQueueable implements Queueable {
    
    private String runGroupId;
    private Integer expectedCount;
    private Integer delayMinutes;
    private Integer retryCount;  

    /**
     * Constructor to initialize with run group ID, expected log count, and retry delay.
     */
    public LogRollupQueueable (String runGroupId, Integer expectedCount, Integer delayMinutes){
        this.runGroupId = runGroupId;
        this.expectedCount = expectedCount;
        this.delayMinutes = delayMinutes;
        this.retryCount = 0;
    }
    
    /**
     * Constructor to for retries, initialized with run group ID, expected log count, retry delay, retryCount.
     */
    public LogRollupQueueable (String runGroupId, Integer expectedCount, Integer delayMinutes, Integer retryCount){
        this.runGroupId = runGroupId;
        this.expectedCount = expectedCount;
        this.delayMinutes = delayMinutes;
        this.retryCount = retryCount;
    }

    public void execute(QueueableContext context){

        // Fetch log records tied to passed in runGroupId
        List<Integration_Log__c> logList = [
            SELECT Id, Integration_Name__c, Message__c, Records_Processed__c, Run_Timestamp__c, Status__c
            FROM Integration_Log__c
            WHERE Run_Group_Id__c = :runGroupId
            ORDER BY Log_Sequence__c ASC
        ];

        if (logList.size() >= expectedCount){
            // Consolidate log records if all jobs finished
            LogRollupService.consolidateLogs(logList);
        } else {
            // Not all logs are present, requeue with minimum of 2x original delay or 10 minutes
            Integer newDelay = Math.min(delayMinutes * 2, 10);            
            System.enqueueJob(new LogRollupQueueable(runGroupId, expectedCount, newDelay, retryCount + 1), newDelay);
        }        
    }    
}