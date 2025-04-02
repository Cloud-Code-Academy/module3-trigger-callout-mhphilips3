/**
 * Tracks state during an integration run.
 * Holds records, messages, flags, and the final Integration_Log__c record.
 */
public with sharing class ProcessingResult {
    
    // Records collected throughout the run
    public List<Article__c> articlesToInsert = new List<Article__c>(); 
    // Messages collected throughout the run for the Custom Logging
    public List<String> messageList = new List<String>{'NewsAPI Sync Log, [Async Process]:'};
    // Flags to determine overall run status (Success, Partial Success, Error)
    public Boolean successRecorded = false;
    public Boolean errorRecorded = false;

    // Log Entry for the run
    public Integration_Log__c logEntry = new Integration_Log__c(
        Integration_Name__c = 'NewsAPI',
        Run_Timestamp__c = Datetime.now(),
        Records_Processed__c = 0
    );

    // Adds a success message to the log and marks the run as having at least one success
    public void addLogSuccess(String successMessage){
        messageList.add(successMessage);
        successRecorded = true;
    }

    // Adds an error message to the log and flags that an error occurred
    public void addLogError(String errorMessage){
        messageList.add(errorMessage);
        errorRecorded = true;
    }

    // Increments the processed record count by the amount in the current iteration
    public void incrementRecordsProcessed(Integer count){
        logEntry.Records_Processed__c += count;
    }

    // Finalizes the log message and sets the status based on what happened during the run
    public void finalizeLogEntry(){
        logEntry.Message__c = String.join(messageList, '\n');
        if(successRecorded && errorRecorded){
            logEntry.Status__c = 'Partial Success';
        } else if (successRecorded){
            logEntry.Status__c = 'Success';
        } else {
            logEntry.Status__c = 'Error';
        }
    }
}