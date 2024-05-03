/*
 * NextStepFuture Class Description:
 * 
 * Question 1: Create a future method that updates all account and opportunities next step to 'Meeting in the future'
 * Question 2: Create a method that inserts a big deal opportunity and updates the user role name to 'CRO'
 * 
 * Benefits of using future methods:
 * 
 * 1. Asynchronous Processing: Allows long-running operations to be handled in the background, freeing up resources.
 * 2. Governor Limit Management: Asynchronous methods have a separate set of limits, providing more flexibility.
 * 3. User Experience Enhancement: Improves responsiveness in user interfaces by offloading processes to the background.
 * 4. Mixed DML Operations Handling: Helps overcome Mixed DML errors by allowing updates on setup and non-setup objects.
 * 5. Enhanced Integration Capabilities: Useful for making callouts to external systems without blocking the user interaction.
 * 
 * For more detailed information, refer to the official Salesforce documentation: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_invoking_future_methods.htm
 * 
 * Note: The class below contains placeholders for implementing a future method to update accounts and opportunities.
 *       The accompanying test class 'AsynchronousTest' should also be updated to test this method.
 */
public with sharing class NextStepFuture {

    /* 
     * Question 1
     * Update/Uncomment the template code to create a method
     * Create a future method that updates all account and opportunities next step to 'Meeting in the future'
     * Account Next Step field is a custom field
     * Opportunity Next Step field is a standard field
     * Update the corresponding test class AsynchronousTest and test method nextStepFuture_testUpdateAllNextStep to cover test this method
     */
    @future
    public static void updateAllNextStep(String nextStep) {
        // Update all accounts next step
        updateAccountsNextStep(nextStep);

        // Update all opportunities next step
        updateOpportunitiesNextStep(nextStep);
    }

    // Helper method to update all Accounts Next Step field
    private static void updateAccountsNextStep(String nextStep) {
        List<Account> accounts = [
            SELECT Id, Next_Step__c
            FROM Account
            WHERE Next_Step__c != :nextStep
        ];
        for (Account acc : accounts) {
            acc.Next_Step__c = nextStep;
        }
        Database.update(accounts);
    }

    // Helper method to update all Opportunities Next Step field
    private static void updateOpportunitiesNextStep(String nextStep) {
        List<Opportunity> opps = [
            SELECT Id, NextStep
            FROM Opportunity
            WHERE NextStep != :nextStep
        ];
        for (Opportunity opp : opps) {
            opp.NextStep = nextStep;
        }
        Database.update(opps);
    }

    /*
    * Question 2
    * Update/Uncomment the template code to create a method
    * Create a method that inserts a big deal opportunity and updates the user role name to 'CRO'
    * Update the corresponding test class AsynchronousTest and test method nextStepFuture_testCreateDealAndUpdateRole to cover test this method
    */
    //Mix DML Error happens when you try to perform DML operations on setup and non-setup objects in a single transaction.
    public static void createDealAndUpdateRole() {
        // update method to bulkify an Opportunity creation.
        insertBigDeal(1);

        // call future method to separate transactions
        updateUserRoleName();
    }

    // Helper method to insert big deals
    private static void insertBigDeal(Integer numOpps) {
        List<Opportunity> bigDeals = new List<Opportunity>();
        for (Integer i = 0; i < numOpps; i++) {
            Opportunity opp = new Opportunity();
            opp.Amount = 1000000;
            opp.Name = 'Big Deal';
            opp.StageName = 'Closed Won'; 
            opp.CloseDate = Date.today();
            bigDeals.add(opp);
        }
        if (bigDeals.size()> 0) {
            Database.insert(bigDeals);
        }
    }

    // Helper method to update role name
    @future
    private static void updateUserRoleName(){
        UserRole[] roles = [
            SELECT Id, Name 
            FROM UserRole 
            WHERE Id = :UserInfo.getUserRoleId() OR Name = 'CRO' 
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        
        UserRole role;
        if (roles.isEmpty()) {
            role = new UserRole();
            role.portalType = 'None'; 
            role.CaseAccessForAccountOwner = 'Edit'; 
            // role.OpportunityAccessForAccountOwner = 'Edit'; //This may need to be uncommented depending on your orgs Organization Wide Defaults(OWD) settings. If you are receiving FIELD_INTEGRITY_EXCEPTION, field integrity exception: unknown (Opportunity access level below organization default): [unknown], uncomment this line.
        } else {
            role = roles[0];
        }

        role.Name = 'CRO';

        // Tried to bypass ApexCRUDViolation, but it doesn't help. I don't know why.
        Schema.DescribeSObjectResult sor = UserRole.SObjectType.getDescribe();
        if (sor.isCreateable() && sor.isUpdateable()) {
            Database.upsert(role);
        }
    }
}