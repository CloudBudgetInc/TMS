/**
 * Created by Alex JR on 11/05/19.
 */
({
    helpGetDrillDown: function (cmp) {
        try {
            _showSpinner(cmp);
            const ddColor = "#30d5c8";
            let action = cmp.get("c.getDrillDown");
            action.setParams({
                "CBalanceKey": cmp.get("v.CBalanceKey"),
                "reportId": cmp.get("v.reportId"),
                "columnId": cmp.get("v.columnId")
            });
            action.setCallback(this, function (response) {
                let state = response.getState();
                if (state === "SUCCESS") {
                    let res = response.getReturnValue();
                    _cl(JSON.stringify(res), ddColor);
                    cmp.set("v.dd", res);
                    cmp.set("v.sections", res.sections);
                    cmp.set("v.warning", res.warning);
                    cmp.set("v.CBalanceRuleId", res.CBalanceRuleId);
                    cmp.set("v.showRedirectToCBalanceLink", res.showRedirectToCBalanceLink);
                    _hideSpinner(cmp);
                } else {
                    _RequestError(response, 'Drill Down failed to load', cmp);
                }
            });
            $A.enqueueAction(action);
        } catch (e) {
            alert("DD = " + e);
        }
    },

});