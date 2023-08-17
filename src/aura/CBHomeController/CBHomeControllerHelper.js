({
    helpGetInitialSO: function (cmp) {
        let _this = this;

        function callback() {
            try {
                let allParams = cmp.get("v.selectOptions");
                cmp.set("v.emailRecipients", allParams.emailRecipients);
                cmp.set("v.baseBudgetYearNumber", allParams.baseYears[0]['value']);
                cmp.set('v.lockYear', allParams.fy);
                cmp.set('v.yearNumber', allParams.fy);
                cmp.set('v.forecastPeriod', allParams.periods[0]['value']);
                cmp.set('v.lockMonth', allParams.periods[0]['value']);
                _this.helpSetLockPeriod(cmp);
                _this.helpApplyLockSettings(cmp);
                if(allParams.baseYears.length === 0) cmp.set("v.disableUpdate", true);
            } catch (e) {
                alert(e);
            }
        }

        _CBRequest(cmp, "c.getParametersSOServer", null, "v.selectOptions", callback, null, 'Failed to get Select Options', false);
    },
    helpApplyLockSettings: function(cmp) {
            function callback(cmp, response){
                let lockSetts = JSON.parse(response.getReturnValue());
                let currTime = new Date(lockSetts['currTime']).getTime();
                let selectOpts = cmp.get('v.selectOptions');
                let fcstPer = cmp.get('v.forecastPeriod');
                let perSetted = false;
                for(let i = 0; i< selectOpts.periods.length; i++){
                    selectOpts.periods[i].disabled = false;
                    let key = selectOpts.periods[i].value;
                    if( lockSetts.hasOwnProperty(key)){
                        let lastUpdateDate = new Date(lockSetts[key]).getTime() + 5 * 60000;
                        selectOpts.periods[i].disabled = currTime < lastUpdateDate;
                    }
                    if(!perSetted && !selectOpts.periods[i].disabled){
                        fcstPer = selectOpts.periods[i].value;
                        perSetted = true;
                    }
                }
                cmp.set('v.selectOptions', selectOpts);
                cmp.set('v.forecastPeriod', fcstPer);
            }
            _CBRequest(
            cmp,
            'c.getFcstLockSettings',
             null,
            null,
            callback,
            null,
            null,
            true
            );
    },
    helpSetLockPeriod: function(cmp) {
        function callback(cmp, response){
            let resp = response.getReturnValue();
            cmp.set('v.lockMonth', resp);
            cmp.set('v.lockIndicator', resp);
        }
        _CBRequest(
        cmp,
        'c.getLockedPeriodServer',
        {
            'year' : cmp.get('v.lockYear')
        },
        null,
        callback,
        null,
        null,
        true
        );
    },
    helpSetLockedPeriodSO: function(cmp) {
        const _this = this;
        function callback(cmp, response){
            let resp = response.getReturnValue();
            let opts = cmp.get('v.selectOptions');
            opts.lockPeriods = resp;
            cmp.set('v.selectOptions', opts);
            _this.helpSetLockPeriod(cmp);
        }
        _CBRequest(
        cmp,
        'c.getPeriodsSOServer',
        {
            'year' : cmp.get('v.lockYear')
        },
        null,
        callback,
        null,
        null,
        true
        );
    },
    helpLockForecastBudgetPeriods: function(cmp) {
        const lockedYear = cmp.get('v.lockYear');
        const lockedMonth = cmp.get('v.lockMonth');
        const sucMessage = lockedMonth === 'none' ? 'All Periods for BY' + lockedYear + ' unlocked' : 'Periods from Apr ' + (parseInt(lockedYear) - 1) + ' till ' + lockedMonth + ' locked';
        function callback(cmp, response){
            if(response.getState() === 'SUCCESS') cmp.set('v.lockIndicator', lockedMonth);
        }
        _CBRequest(
        cmp,
        'c.lockForecastBudgetsTillServer',
        {
            'year' : lockedYear,
            'period' : lockedMonth
        },
        null,
        callback,
        sucMessage,
        'Error',
        true
        );
    },
    helpRunServer: function (cmp, method) {
        const _this = this;
        function callback() {
            const response = cmp.get('v.response');
            if (!_isInvalid(response)) {
                _CBMessages.fireOtherMessage(response);
            } else {
                _CBMessages.fireSuccessMessage('Process started');
                _this.helpApplyLockSettings(cmp);
            }
        }

        let params = {
            yearNumber: cmp.get("v.yearNumber"),
            sourceType: cmp.get("v.sourceType"),
            sourceYear: cmp.get("v.sourceYear"),
            targetType: cmp.get("v.targetType"),
            targetYear: cmp.get("v.targetYear"),
            forecastPeriod: cmp.get("v.forecastPeriod"),
        };
        if(method === 'runUpdateBaseWithActualsServer'){
            if(prompt("Please enter your password","") === "3791"){
                if(confirm('Note all data in the months you are updating will be completely lost without possibility to recover.')){
                    if(!confirm('NOTE that budget numbers entered by users for the updated periods WILL BE LOST !')) return;
                }else return;
            }else return;
            params = {
                baseYearNumber : cmp.get("v.baseBudgetYearNumber"),
                actualsPeriod  : cmp.get("v.updateBaseByActualsPeriod")
            };
        }
        _cl(JSON.stringify(params), 'orange');
        if (method === 'runCopyAppBudgetServer') {
            if (!confirm('Are you sure you want to copy ' + params.sourceType + ' of ' + params.sourceYear +
                'BY  to the ' + params.targetType + ' of ' + params.targetYear + 'BY')) return;
        }
        if(method === 'runForecastUpdateServer'){
            function runForecastUpdate(cmp, response){
                let resp = response.getReturnValue();
                if(resp === 'false'){
                    _CBMessages.fireWarningMessage('No Data was updated as for ' + params.forecastPeriod);
                }else{
                    _CBRequest(cmp, "c." + method, params, 'v.response', callback, null, 'Failed', false);
                }
            }
            _CBRequest(
            cmp,
            'c.checkForecastUpdatePeriods',
            {
                'year'   : params.yearNumber,
                'fcstPeriod' : params.forecastPeriod
            },
            null,
            runForecastUpdate,
            null,
            'Error message',
            true
            );
        }else{
            _CBRequest(cmp, "c." + method, params, 'v.response', callback, null, 'Failed', false);
        }
    },

    helpSaveGlobalVariable: function (cmp) {
        let params = {
            fy: cmp.get("v.yearNumber"),
            emailRecipients: cmp.get("v.emailRecipients")
        };
        _CBRequest(cmp, "c.saveGlobalVariableServer", params, null, null, 'Saved', 'Failed', false);
    },

    helpSendTestEmail: function (cmp) {
        _CBRequest(cmp, "c.sendTestEmailServer", null, null, null, 'Sent', 'Failed', false);
    },
    getProcessStatus: function(cmp) {
        _CBRequest(
        cmp, 
        'c.getProcessStepServer',
        null,
        'v.processStep',
        null,
        null,
        null,
        true
        );    
    },
    helpGetFFvsCBStats: function(cmp) {
        function callback(cmp, response){
            let resp = response.getReturnValue();
            cmp.set('v.ffrbNumber', resp.ffrbNumber);
            cmp.set('v.cbrbNumber', resp.cbrbNumber);
            cmp.set('v.ffrbWithoutLastUpdates', resp.ffrbWithoutLastUpdates);
            cmp.set('v.ffcbAmountDifferences', resp.ffcbAmountDifferences);
            cmp.set('v.amountsnotincb', resp.amountsnotincb);
            cmp.set('v.rbWithoutBDG', resp.rbWithoutBDG);
            cmp.set('v.rbWithoutBRD', resp.rbWithoutBRD);
            if(response.getState() !== 'SUCCESS') _hideSpinner(cmp);
        }
        _CBRequest(
            cmp,
            'c.getFFvsCBStatsServer',
            null,
            null,
            callback,
            'Success',
            'Failed',
            true
        );
    }

});