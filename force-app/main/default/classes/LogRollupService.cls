/**
 * Utility class for consolidating Integration Log records
 * tied together by a shared Run Group ID.
 */
public with sharing class LogRollupService {

    /**
     * Consolidates Integration_Log__c records with the same Run_Group_Id__c
     * into a single summary record. Deletes the original logs after rollup.
     * 
     * @param runGroupId The shared identifier across multiple logs
     */
    public static void consolidateLogs(List<Integration_Log__c> logsToMerge){

        // Initiate build-out of consolidated log record
        Integration_Log__c finalLog = new Integration_Log__c(
            Integration_Name__c = logsToMerge[0].Integration_Name__c,
            Run_Timestamp__c = logsToMerge[0].Run_Timestamp__c,
            Records_Processed__c = 0
        );

        Boolean hadSuccess = false;
        Boolean hadError = false;
        List<String> messageList = new List<String>{
            'Aggregated summary from NewsAPI category sync, run on ' + finalLog.Run_Timestamp__c.date().format()
        };

        // Consolidate initial logs
        for(Integration_Log__c log : logsToMerge){
            messageList.add(log.Message__c);
            finalLog.Records_Processed__c += log.Records_Processed__c;

            if (log.Status__c == 'Success'){
                hadSuccess = true;
            } else if (log.Status__c == 'Error'){
                hadError = true;
            } else {
                hadError = true;
                hadSuccess = true;
            }
        }

        // Complete final log build-out
        if(hadError && hadSuccess){
            finalLog.Status__c = 'Partial Success';
        } else if (hadSuccess) {
            finalLog.Status__c = 'Success';
        } else {
            finalLog.Status__c = 'Error';
        }

        finalLog.Message__c = String.join(messageList, '\n\n');
        insert finalLog;
        delete logsToMerge;
    }    
}