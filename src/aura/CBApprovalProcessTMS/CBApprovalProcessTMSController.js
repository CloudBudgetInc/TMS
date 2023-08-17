/**
 * Created by Alex JR on 11/10/2020.
 */
({
    runInit: function (cmp, event, helper) {
  		helper.helpGetTag(cmp, event);
    },
    callReject: function (cmp, event, helper) {
        helper.helpCallReject(cmp, event);
    },
    callSubmit: function (cmp, event, helper) {
        helper.helpCallSubmit(cmp, event);
    },
    callApprove: function (cmp, event, helper) {
        helper.helpCallApprov(cmp, event);
    },
});