/**
 * Created by Alex JR on 11/05/19.
 */
({
    doInit: function (cmp, event, helper) {
        helper.helpGetDrillDown(cmp);
    },
    closeDrillDown: function (cmp, event, helper) {
        $A.util.addClass(cmp.find('mainPanel'), 'slds-hide');
    },
    redirectLink: function (cmp, event, helper) {
        if (event.target.id === '') return null;
        window.open('/' + event.target.id);
    },
    redirectToCBalances: function (cmp, event, helper) {
        _CBRedirect.toComponent('c:CBalanceConfigurator', {'selectedId': cmp.get('v.CBalanceRuleId')});
    }
});