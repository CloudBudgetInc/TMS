/**
 * Created by Alex JR on 11/10/2020.
 */

public with sharing class CBApprovalProcessTMS {

    @AuraEnabled
    public static List<cb4__CBTag__c> getBudgetsListToApprove() {
        Id currentuser = system.UserInfo.getUserId();
        List<cb4__CBTag__c> result;
        result = [
                select cb4__Tag3Name__c,cb4__Tag8Name__c,Id, Owner.Name, Name, cb4__Tag1Name__c, Submitter__c, Submitter__r.Name, cb4__Status__c, SubmittTime__c
                from cb4__CBTag__c
                where cb4__DimensionName__c = 'Budget App' and cb4__Status__c = 'Submitted' and DesignatedApprover__c = :currentuser
        ];
        return result;
    }
/*26.12.2022 backup submitTag*/
/*
    @AuraEnabled
    public static cb4__CBTag__c submitTag(Map<String, String> parametersObject) {
        cb4__CBTag__c test;

        String appId = parametersObject.get('appId');
        String userId = parametersObject.get('userId');
        String designatedApproverId = parametersObject.get('designatedApproverId');
        if(designatedApproverId == null) String s = test.cb4__Text1__c; // null pointer exception

        cb4__CBTag__c tag = [select Id,cb4__Status__c,Submitter__c,SubmittTime__c,DesignatedApprover__c from cb4__CBTag__c where id = :appId];
        tag.cb4__Status__c = APPROV_STATUS_SUBMITTED;
        tag.Submitter__c = userId;
        tag.SubmittTime__c = DateTime.now();
        tag.DesignatedApprover__c = designatedApproverId;
        
        if (tag.DesignatedApprover__c == null) Integer i = 1 / 0;// 0 dividing exception


        update tag;
        return tag;
    }

*/    
    
    @AuraEnabled
    public static cb4__CBTag__c submitTag(Map<String, String> parametersObject) {
        cb4__CBTag__c test;

        String appId = parametersObject.get('appId');
        String userId = parametersObject.get('userId');
        String designatedApproverId = parametersObject.get('designatedApproverId');
        if(designatedApproverId == null) String s = test.cb4__Text1__c; // null pointer exception

        cb4__CBTag__c tag = [select Id,cb4__Status__c,Submitter__c,SubmittTime__c,DesignatedApprover__c from cb4__CBTag__c where id = :appId];
        tag.cb4__Status__c = APPROV_STATUS_SUBMITTED;
        tag.Submitter__c = userId;
        tag.SubmittTime__c = DateTime.now();
        tag.DesignatedApprover__c = designatedApproverId;
        
        if (tag.DesignatedApprover__c == null) Integer i = 1 / 0;// 0 dividing exception
        update tag;
        List<cb4__CBTag__c> tags = getChildren(tag.Id);
        List<cb4__CBTag__c> tagsToUpdate = new List<cb4__CBTag__c>();
        for (cb4__CBTag__c curr : tags) {
            if ((curr.cb4__Status__c == APPROV_STATUS_OPEN) && (curr.Id != Tag.Id)) {
              curr.cb4__Status__c = APPROV_STATUS_LOCKED;
              curr.Approver__c = userId;  
              tagsToUpdate.add(curr); 
            }
         }
        if (tagsToUpdate.size()>0) {
           update  tagsToUpdate;
        } 
        return tag;
    }

    @AuraEnabled
    public static cb4__CBTag__c approveTag(Id tagId, Id userId) {
        if (tagId != null) {
            List<cb4__CBTag__c> tags = getChildren(tagId);
            for (cb4__CBTag__c curr : tags) {
                curr.cb4__Status__c = APPROV_STATUS_APPROVED;
                curr.Approver__c = userId;
            }
            update tags;
            return tags[0];
        }
        return null;
    }

    @AuraEnabled
    public static cb4__CBTag__c rejectTag(Id tagId, Id userId) {
        if (tagId != null) {
            List<cb4__CBTag__c> tags = getChildren(tagId);
            for (cb4__CBTag__c curr : tags) {
                curr.cb4__Status__c = APPROV_STATUS_OPEN;
                curr.Approver__c = userId;
            }
            update tags;
            return tags[0];
        }
        return null;
    }

    static List<cb4__CBTag__c> getChildren(Id tagId) {
        List<cb4__CBTag__c> result = new List<cb4__CBTag__c>();
        if (tagId == null) {
            return result;
        }
        result.add([Select ownerid,Id,cb4__Status__c, Submitter__c,Approver__c from cb4__CBTag__c where Id = :tagId and cb4__DimensionName__c = 'Budget App']);

        List<Id> level1children = new List<Id>();
        List<Id> level2children = new List<Id>();
        List<Id> level3children = new List<Id>();
        List<Id> level4children = new List<Id>();
        List<Id> level5children = new List<Id>();
        List<Id> level6children = new List<Id>();

        for (cb4__CBTag__c curr : [Select ownerid,Id,cb4__Status__c, Submitter__c,Approver__c from cb4__CBTag__c where cb4__Tag1__c = :tagId and cb4__DimensionName__c = 'Budget App']) {
            level1children.add(curr.Id);result.add(curr);
        }

        if (!level1children.isEmpty()) {
            for (cb4__CBTag__c curr : [Select ownerid,Id,cb4__Status__c, Submitter__c,Approver__c from cb4__CBTag__c where cb4__Tag1__c in :level1children and cb4__DimensionName__c = 'Budget App']) {
                level2children.add(curr.Id); result.add(curr);
            }
        }
        if (!level2children.isEmpty()) {
            for (cb4__CBTag__c curr : [Select ownerid,Id,cb4__Status__c, Submitter__c,Approver__c from cb4__CBTag__c where cb4__Tag1__c in :level2children and cb4__DimensionName__c = 'Budget App']) {
                level3children.add(curr.Id); result.add(curr);
            }
        }
        if (!level3children.isEmpty()) {
            for (cb4__CBTag__c curr : [Select ownerid,Id,cb4__Status__c, Submitter__c,Approver__c from cb4__CBTag__c where cb4__Tag1__c in :level3children and cb4__DimensionName__c = 'Budget App']) {
                level4children.add(curr.Id); result.add(curr);
            }
        }
        if (!level4children.isEmpty()) {
            for (cb4__CBTag__c curr : [Select ownerid,Id,cb4__Status__c, Submitter__c,Approver__c from cb4__CBTag__c where cb4__Tag1__c in :level4children and cb4__DimensionName__c = 'Budget App']) {
                level5children.add(curr.Id); result.add(curr);
            }
        }
        if (!level5children.isEmpty()) {
            for (cb4__CBTag__c curr : [Select ownerid,Id,cb4__Status__c, Submitter__c,Approver__c from cb4__CBTag__c where cb4__Tag1__c in :level5children and cb4__DimensionName__c = 'Budget App']) {
                level6children.add(curr.Id); result.add(curr);
            }
        }
        if (!level6children.isEmpty()) {
            for (cb4__CBTag__c curr : [Select ownerid,Id,cb4__Status__c, Submitter__c,Approver__c from cb4__CBTag__c where cb4__Tag1__c in :level6children and cb4__DimensionName__c = 'Budget App']) {
                result.add(curr);
            }
        }

        return result;
    }

    public static final String APPROV_STATUS_OPEN = 'Open';
    public static final String APPROV_STATUS_SUBMITTED = 'Submitted';
    public static final String APPROV_STATUS_APPROVED = 'Approved';
	public static final String APPROV_STATUS_LOCKED = 'Locked';
  /* 25.11.2022 getTagById prev. version
    @AuraEnabled
    public static cb4__CBTag__c getTagById(Id tagId) {
        Boolean isSubmitVisible = false;
        Boolean isApproveVisible = false;
        Boolean isRejectVisible = false;
        Id designatedApprover = null;
        User designatedApproverUser = null;
        String checkString = 'first';
        User currentUser;
        User budgetOwner;
        Boolean hasChild;
        Boolean isZeroLevelBudget;
        User parentBudgetOwner;

        cb4__CBTag__c budget = [
                SELECT ParentOwner__c,owner.Name,ownerid,Id,cb4__Tag1__c,cb4__Status__c, Submitter__c, Submitter__r.Name,
                        Approver__c, Approver__r.Name, DesignatedApprover__c, DesignatedApprover__r.Name,
                        cb4__Boolean1__c,cb4__Boolean2__c,cb4__Boolean3__c,CB4__Text1__c,cb4__Text2__c,cb4__Text3__c
                from cb4__CBTag__c
                where Id = :tagid
        ][0];

        List<cb4__CBTag__c> subBudgets = [Select Id from cb4__CBTag__c where cb4__Tag1__c = :tagId and cb4__DimensionName__c = 'Budget App' limit 1];
        currentUser = [SELECT Id,Name,CBBudgetManager__c from user where Id = :system.UserInfo.getUserId()][0];
        budgetOwner = [SELECT Id,CBBudgetManager__c,CBBudgetManager__r.Name from user where Id = :budget.ownerid][0];

        isZeroLevelBudget = budget.cb4__Tag1__c == null;
        hasChild = subBudgets.size() == 1;
        parentBudgetOwner = null;


        if (!isZeroLevelBudget) {
            parentBudgetOwner = [SELECT Id,Name,CBBudgetManager__c from user where Id = :budget.ParentOwner__c][0];
        }

        if (budget.cb4__Status__c == APPROV_STATUS_OPEN) {
            checkString += ':' + APPROV_STATUS_OPEN;
            if (budgetOwner.Id == currentUser.Id ) { 
                                               //|| (budgetOwner.CBBudgetManager__c != null && budgetOwner.CBBudgetManager__c == currentUser.Id)
                checkString += ':isUser';
                if (isZeroLevelBudget) {
                    checkString += ':isZeroLevelBudget';
                    if (budgetOwner.Id == currentUser.Id && budgetOwner.CBBudgetManager__c == null) {
                        checkString += ':isBossSubmitVisible1';
                        isSubmitVisible = true;
                        designatedApprover = currentUser.Id;
                    }
                } else {
                    checkString += ':notZeroLevel';
                    if (hasChild) {
                        checkString += ':hasChild';
                        if (budgetOwner.Id == currentUser.Id && budgetOwner.CBBudgetManager__c == null) {
                            checkString += ':IsBossSubmi2';
                            isSubmitVisible = true;
                            designatedApprover = currentUser.Id;
                        } else {
                            checkString += ':notBoss2';
                            if (parentBudgetOwner.Id == budgetOwner.Id) {
                                checkString += ':sameowner1hide';
                                // hide Buttons
                            } else {
                                checkString += ':sameowner1SubmitVisible3';
                                isSubmitVisible = true;
                                designatedApprover = budgetOwner.CBBudgetManager__c;
                            }
                        }
                    } else {
                        checkString += ':nothasChild';
                        if (parentBudgetOwner.Id == budgetOwner.Id) {
                            // hide Buttons
                            checkString += ':sameowner2hide';
                        } else {
                            checkString += ':sameowner2SubmitVisible4';
                            isSubmitVisible = true;
                            designatedApprover = budgetOwner.CBBudgetManager__c;
                        }
                    }
                }
            }
        } else {
            if (budget.cb4__Status__c == APPROV_STATUS_SUBMITTED && currentUser.Id == budget.DesignatedApprover__c) {
                checkString += ':' + APPROV_STATUS_SUBMITTED;
                isApproveVisible = true;
                isRejectVisible = true;
                designatedApprover = budget.DesignatedApprover__c;
            } else {
                if (budget.cb4__Status__c == APPROV_STATUS_APPROVED && currentUser.Id == budget.DesignatedApprover__c && currentUser.Id == budget.Approver__c) {
                    checkString += ':' + APPROV_STATUS_APPROVED;
                    isRejectVisible = true;
                    designatedApprover = budget.DesignatedApprover__c;
                }
            }
        }
        if (designatedApprover != null) {
            designatedApproverUser = [SELECT Id,Name,CBBudgetManager__c from user where Id = :designatedApprover][0];
        }


        budget.cb4__Boolean1__c = isSubmitVisible;
        budget.cb4__Boolean2__c = isApproveVisible;
        budget.cb4__Boolean3__c = isRejectVisible;
        budget.cb4__Boolean4__c = hasChild;
        budget.cb4__Boolean5__c = budget.cb4__Status__c == APPROV_STATUS_APPROVED;
        budget.cb4__Boolean6__c = (budget.cb4__Status__c == APPROV_STATUS_APPROVED) || (budget.cb4__Status__c == APPROV_STATUS_SUBMITTED) 
                                                           || isSubmitVisible || isApproveVisible || isRejectVisible;
        budget.CB4__Text1__c = budget.Submitter__r.Name == null ? '-' : budget.Submitter__r.Name;
        budget.cb4__Text2__c = budget.Approver__r.Name == null ? '-' : budget.Approver__r.Name;
        budget.cb4__Text3__c = designatedApprover == null ? '-' : designatedApprover;
        budget.cb4__Text4__c = budget.owner.Name;
        budget.cb4__Text5__c = designatedApprover == null ? '-' : designatedApproverUser.Name ;
        budget.cb4__Text6__c = budgetOwner.CBBudgetManager__r.Name;
        budget.cb4__Text7__c = parentBudgetOwner == null ? '-' : parentBudgetOwner.Name;
        budget.cb4__Text8__c = checkString;
        budget.cb4__Text9__c = currentUser.Name;
        budget.cb4__User__c = currentUser.Id;
        budget.DesignatedApprover__c = designatedApprover;


        return budget;

    }*/
    
   @AuraEnabled
    public static cb4__CBTag__c getTagById(Id tagId) {
        Boolean isSubmitVisible = false;
        Boolean isApproveVisible = false;
        Boolean isRejectVisible = false;
        Id designatedApprover = null;
        User designatedApproverUser = null;
        String checkString = 'first';
        User currentUser;
        User budgetOwner;
        Boolean hasChild;
        Boolean isZeroLevelBudget;
        User parentBudgetOwner;

        cb4__CBTag__c budget = [
                SELECT ParentStatus__c,ParentOwner__c,owner.Name,ownerid,Id,cb4__Tag1__c,cb4__Status__c, Submitter__c, Submitter__r.Name,
                        Approver__c, Approver__r.Name, DesignatedApprover__c, DesignatedApprover__r.Name,
                        cb4__Boolean1__c,cb4__Boolean2__c,cb4__Boolean3__c,CB4__Text1__c,cb4__Text2__c,cb4__Text3__c
                from cb4__CBTag__c
                where Id = :tagid
        ][0];
        
        List<cb4__CBTag__c> subBudgets = [Select Id from cb4__CBTag__c where cb4__Tag1__c = :tagId and cb4__DimensionName__c = 'Budget App' limit 1];
        currentUser = [SELECT Id,Name,CBBudgetManager__c from user where Id = :system.UserInfo.getUserId()][0];
        budgetOwner = [SELECT Id,CBBudgetManager__c,CBBudgetManager__r.Name from user where Id = :budget.ownerid][0];

        isZeroLevelBudget = budget.cb4__Tag1__c == null;
        hasChild = subBudgets.size() == 1;
        parentBudgetOwner = null;


        if (!isZeroLevelBudget) {
            parentBudgetOwner = [SELECT Id,Name,CBBudgetManager__c from user where Id = :budget.ParentOwner__c][0];
        }

        if (budget.cb4__Status__c == APPROV_STATUS_OPEN) {
            checkString += ':' + APPROV_STATUS_OPEN;
            if (budgetOwner.Id == currentUser.Id ) {
                checkString += ':isUser';
                if (isZeroLevelBudget) {
                    checkString += ':ZeroLevelBudget';
                    isSubmitVisible = true;
                    designatedApprover = budgetOwner.Id;
                } else {
					checkString += ':noZeroLevelBudget';
                    isSubmitVisible = true;
                    designatedApprover = parentBudgetOwner.Id;
                }                               
            }        
        } else {
            if (budget.cb4__Status__c == APPROV_STATUS_SUBMITTED && currentUser.Id == budget.DesignatedApprover__c) {
                checkString += ':' + APPROV_STATUS_SUBMITTED;
                isApproveVisible = true;
                isRejectVisible = true;
                designatedApprover = budget.DesignatedApprover__c;
            } else {
                if (budget.cb4__Status__c == APPROV_STATUS_APPROVED && 
                                            budget.ParentStatus__c != APPROV_STATUS_APPROVED && 
                                            currentUser.Id == budget.DesignatedApprover__c && currentUser.Id == budget.Approver__c) {
                    checkString += ':' + APPROV_STATUS_APPROVED;
                    isRejectVisible = true;
                    designatedApprover = budget.DesignatedApprover__c;
                }
            }
        }
        if (designatedApprover != null) {
            designatedApproverUser = [SELECT Id,Name,CBBudgetManager__c from user where Id = :designatedApprover][0];
        }


        budget.cb4__Boolean1__c = isSubmitVisible;
        budget.cb4__Boolean2__c = isApproveVisible;
        budget.cb4__Boolean3__c = isRejectVisible;
        budget.cb4__Boolean4__c = hasChild;
        budget.cb4__Boolean5__c = budget.cb4__Status__c == APPROV_STATUS_APPROVED;
        budget.cb4__Boolean6__c = (budget.cb4__Status__c == APPROV_STATUS_APPROVED) || (budget.cb4__Status__c == APPROV_STATUS_SUBMITTED) 
            											   || (budget.cb4__Status__c == APPROV_STATUS_LOCKED) 
                                                           || isSubmitVisible || isApproveVisible || isRejectVisible;
        budget.CB4__Text1__c = budget.Submitter__r.Name == null ? '-' : budget.Submitter__r.Name;
        budget.cb4__Text2__c = budget.Approver__r.Name == null ? '-' : budget.Approver__r.Name;
        budget.cb4__Text3__c = designatedApprover == null ? '-' : designatedApprover;
        budget.cb4__Text4__c = budget.owner.Name;
        budget.cb4__Text5__c = designatedApprover == null ? '-' : designatedApproverUser.Name ;
        budget.cb4__Text6__c = budgetOwner.CBBudgetManager__r.Name;
        budget.cb4__Text7__c = parentBudgetOwner == null ? '-' : parentBudgetOwner.Name;
        budget.cb4__Text8__c = checkString;
        budget.cb4__Text9__c = currentUser.Name;
        budget.cb4__User__c = currentUser.Id;
        budget.DesignatedApprover__c = designatedApprover;


        return budget;

    }

}