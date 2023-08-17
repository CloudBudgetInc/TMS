/**
 * Created by Alex JR on 11/10/2020.
 */
({

    helpGetTag: function (cmp, event) {
        let app = cmp.get('v.app');
        _cl('Tag ' + JSON.stringify(app), "green");
        let appId = app.Id;
        _cl('apappId ' + appId, "red");
        let action = cmp.get("c.getTagById");
        action.setParams({
            "tagId": appId
        });
        action.setCallback(this, function (response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                let result = response.getReturnValue();
                _cl('Tag ' + JSON.stringify(result), "blue");
                _cl('Log ' + result.cb4__Text8__c, "red"); 
                _cl('isDisplayed ' + result.cb4__Boolean6__c, "red");
                _cl('isSubmitButtonDisplayed ' + result.cb4__Boolean1__c, "red");
                if (result != null) {
                    cmp.set("v.approverName", result.cb4__Text2__c);
                    cmp.set("v.designatedApproverId", result.DesignatedApprover__c);
                    cmp.set("v.designatedApproverName", result.cb4__Text5__c);
                    cmp.set("v.isSubmitButtonDisplayed", result.cb4__Boolean1__c);
                    cmp.set("v.isApproveButtonDisplayed", result.cb4__Boolean2__c);
                    cmp.set("v.isRejectButtonDisplayed", result.cb4__Boolean3__c);
                    cmp.set("v.hasChildren", result.cb4__Boolean4__c);
                    cmp.set("v.isApprovedStatus", result.cb4__Boolean5__c);
                    cmp.set("v.isDisplayed", result.cb4__Boolean6__c);
                    cmp.set("v.currentUserId", result.cb4__User__c);
                    cmp.set("v.approvalStatus", result.cb4__Status__c);
                }
            } else {
                _cl('helpGetTag get error', 'red');
                let errors = response.getError();
                let message = 'Unknown error';
                if (errors && Array.isArray(errors) && errors.length > 0) message = errors[0].message;
                _cl(message, 'red');
            }
        });
        $A.enqueueAction(action);
    },
    helpCallSubmit: function (cmp, event) {
        let app = cmp.get('v.app');
        _cl('helpCallAction', 'red');
        if (!confirm('Are you sure to submit current Budget ?')) {
            return;
        }
        let action;
        let designatedApproverId = cmp.get("v.designatedApproverId");
        let appId = app.Id;
        let userId = cmp.get("v.currentUserId");
        _cl('Open designatedApproverId ' + designatedApproverId, 'red');
        _cl('Open userId ' + userId, 'red');
        _cl('Open appId ' + appId, 'red');
        action = cmp.get("c.submitTag");
        let parametersObject = {};
        parametersObject.appId = appId;
        parametersObject.userId = userId;
        parametersObject.designatedApproverId = designatedApproverId;
        action.setParams({
            "parametersObject": parametersObject
        });
        action.setCallback(this, function (response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                let result = response.getReturnValue();
                $A.get('e.force:refreshView').fire();
            } else {
                _cl('error', 'red');
                let errors = response.getError();
                let message = 'Unknown error';
                if (errors && Array.isArray(errors) && errors.length > 0) message = errors[0].message;
                _cl('' + JSON.stringify(errors), 'red');
            }
        });
        $A.enqueueAction(action);

    },
    helpCallApprov: function (cmp, event) {
        let app = cmp.get('v.app');
        let hasChildren = cmp.get('v.hasChildren');
        if (hasChildren) {
            if (!confirm('Are you sure to approve current Budget and all subsidiaries budgets?')) {
                return;
            }
        } else {
            if (!confirm('Are you sure to approve current Budget ?')) {
                return;
            }
        }
        let action = cmp.get("c.approveTag");
        let userId = cmp.get("v.currentUserId");
        action.setParams({
            "tagId": app.Id,
            "userId": userId
        });
        action.setCallback(this, function (response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                let result = response.getReturnValue();
                if (result != null) {
                    $A.get('e.force:refreshView').fire();
                }
            } else {
                let errors = response.getError();
                let message = 'Unknown error';
                if (errors && Array.isArray(errors) && errors.length > 0) message = errors[0].message;
                _cl(message, 'red');
            }
        });
        $A.enqueueAction(action);
    },
   
    helpCallReject: function (cmp, event) {
        let app = cmp.get('v.app');
        let hasChildren = cmp.get('v.hasChildren');
        if (hasChildren) {
            if (!confirm('Are you sure to reject current Budget and all subsidiaries budgets?')) {
                return;
            }
        } else {
            if (!confirm('Are you sure to reject current Budget ?')) {
                return;
            }
        }
        let action = cmp.get("c.rejectTag");
        let userId = cmp.get("v.currentUserId");
        action.setParams({
            "tagId": app.Id,
            "userId": userId
        });
        action.setCallback(this, function (response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                let result = response.getReturnValue();
                if (result != null) {
                    $A.get('e.force:refreshView').fire();
                }
            } else {
                let errors = response.getError();
                let message = 'Unknown error';
                if (errors && Array.isArray(errors) && errors.length > 0) message = errors[0].message;
                _cl(message, 'red');
            }
        });
        $A.enqueueAction(action);
    },
    _cl: function (cmp, event) {
        try {
            if (typeof message === "object") message = message.toString();
            console.log('%c🌩️ ' + message, 'color:' + color + '; ' +
                'font: 1 Tahoma; ' +
                'font-size: 1.2em; ' +
                'font-weight: bolder; ' +
                'padding: 2px;');
        } catch (e) {

        }
    }
});