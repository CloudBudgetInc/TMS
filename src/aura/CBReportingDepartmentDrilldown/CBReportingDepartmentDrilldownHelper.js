/**
 * Created by Alex JR on 10/26/2020. 
 */
({

    helpGetDrillDown: function (cmp) {
        try {
            _showSpinner(cmp);
            let action = cmp.get("c.getDrillDownServer");
            action.setParams({
                "ffrbId": cmp.get("v.recordId"),
                'ffrbName': cmp.get("v.FFRBName")
            });
            action.setCallback(this, function (response) {
                let state = response.getState();
                if (state === "SUCCESS") {
                    let res = response.getReturnValue();
                    _cl(JSON.stringify(res), 'red');
                    cmp.set("v.result", res);
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