({
    runInit: function (cmp, event, helper) {
        document.onkeydown = function(evt) {
            evt = evt || window.event;

            if (evt.ctrlKey && evt.keyCode == 222) {
                let hBtns = cmp.find('hiddenButtons');
                hBtns.forEach(btn => {
                    if($A.util.hasClass(btn, "slds-hide")) $A.util.removeClass(btn, 'slds-hide');
                    else $A.util.addClass(btn, 'slds-hide');
                });
            }
        };
        helper.helpGetInitialSO(cmp);
        helper.helpApplyLockSettings(cmp);
        helper.getProcessStatus(cmp);
    },

    updateProcessStatus: function(cmp, evt, h) {
        h.getProcessStatus(cmp);
    },

    runServer: function (cmp, event, helper) {
        helper.helpRunServer(cmp, event.getSource().get("v.value"));
    },

    changeGlobalVariable: function (cmp, event, helper) {
        if (confirm("Are you sure you want to change the global parameters of the organization?")) {
            helper.helpSaveGlobalVariable(cmp);
            helper.helpGetInitialSO(cmp);
            cmp.set('v.updateBaseByActualsPeriod','Up to Date');
        } else {

        }
    },

    handleMainMenu: function (cmp, event, helper) {
        let selectedMenuItemValue = event.getParam("value");

        switch (selectedMenuItemValue) {
            case 'redirectToApexJobs':
                let win = window.open('/apexpages/setup/listAsyncApexJobs.apexp', '_blank');
                win.focus();
                break;
            case 'doSomethingStupid':
                break;
            default:
        }
    },

    sendTestEmail: function (cmp, event, helper) {
        helper.helpSendTestEmail(cmp);
    },
    lockForecastBudgetsTill: function(cmp, evt, h) {
        h.helpLockForecastBudgetPeriods(cmp);
    },
    refreshLockedPeriods: function(cmp, evt, h) {
        h.helpSetLockedPeriodSO(cmp);
    },
    refreshCurrentUpdateStatuses: function(cmp, evt, h) {
        h.helpApplyLockSettings(cmp);
    },
    refreshFFRBvsCBRBSyncStatus: function(cmp, evt, h) {
        h.helpGetFFvsCBStats(cmp);
    }
});