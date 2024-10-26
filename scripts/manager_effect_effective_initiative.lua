--  	Author: Ryan Hagelstrom
--      Copyright © 2021-2024
--      Please see the license file included with this distribution for
--      attribution and copyright information.
--
-- luacheck: globals customRoundStart reevaluateAllEffects reevaluateEffects customHandleApplyInit customOnTurnStartEvent customNextActor onInit
-- luacheck: globals RRRollManager Pets
local handleApplyInit = nil;
local onTurnStartEvent = nil;
local nextActor = nil;

-- Counter of outstanding init rolls
local nOutstandingRolls = 0;

function customRoundStart()
    if OptionsManager.isOption('HRIR', 'on') then
        if User.getRulesetName() == '5E' and RRRollManager and not OptionsManager.isOption('EFFECTIVE_INITIATIVE', 'off') then
            nOutstandingRolls = 0;
            local ctEntries = CombatManager.getCombatantNodes();
            for _, nodeCT in pairs(ctEntries) do
                local bCohort = false;
                if Pets then
                    bCohort = Pets.isCohort(nodeCT);
                end
                local bPC = ActorManager.isPC(nodeCT);
                if OptionsManager.isOption('EFFECTIVE_INITIATIVE', 'all') or
                    (OptionsManager.isOption('EFFECTIVE_INITIATIVE', 'pcsonly') and bPC) or
                    (OptionsManager.isOption('EFFECTIVE_INITIATIVE', 'pcs') and (bPC or bCohort)) then
                    nOutstandingRolls = nOutstandingRolls + 1;
                    RRRollManager.onButtonPress('init', nodeCT);
                end
            end
            if nOutstandingRolls == 0 then
                reevaluateAllEffects();
            end
        else
            reevaluateAllEffects();
        end
    end
end

function reevaluateAllEffects()
    local ctEntries = CombatManager.getCombatantNodes();
    for _, nodeCT in pairs(ctEntries) do
        reevaluateEffects(nodeCT);
    end
end

function reevaluateEffects(nodeCT)
    for _, nodeEffect in pairs(DB.getChildren(nodeCT, 'effects')) do
        if (DB.getValue(nodeEffect, 'duration', '') ~= 0) then
            local sSource = DB.getValue(nodeEffect, 'source_name', '');
            if sSource == '' then
                sSource = ActorManager.getCTPathFromActorNode(nodeCT);
            end
            local nodeSource = ActorManager.getCTNode(sSource);
            local nInit = DB.getValue(nodeSource, 'initresult', 0);
            DB.setValue(nodeEffect, 'init', 'number', nInit);
        end
    end
end

function customHandleApplyInit(msgOOB)
    handleApplyInit(msgOOB);
    if nOutstandingRolls > 0 then
        nOutstandingRolls = nOutstandingRolls - 1;
        -- Wait until everything is settled before readjusting the order of the effects
        if nOutstandingRolls == 0 then
            reevaluateAllEffects();
            nextActor();
        end
    end
end

function customOnTurnStartEvent(nodeCT)
    if nOutstandingRolls == 0 then
        onTurnStartEvent(nodeCT);
    end
end

function customNextActor(SkipBell, bNoRoundAdvance)
    if nOutstandingRolls == 0 then
        nextActor(SkipBell, bNoRoundAdvance);
    end
end

function onInit()
    if Session.IsHost then
        CombatManager.setCustomRoundStart(customRoundStart);
        if User.getRulesetName() == '5E' then
            OOBManager.registerOOBMsgHandler(ActionInit.OOB_MSGTYPE_APPLYINIT, customHandleApplyInit);

            handleApplyInit = ActionInit.handleApplyInit;
            nextActor = CombatManager.nextActor;
            onTurnStartEvent = CombatManager.onTurnStartEvent;
            ActionInit.handleApplyInit = customHandleApplyInit;
            CombatManager.onTurnStartEvent = customOnTurnStartEvent;
            CombatManager.nextActor = customNextActor;

            OptionsManager.registerOption2('EFFECTIVE_INITIATIVE', false, 'option_effective_initiative', 'option_ei_rr',
                                           'option_entry_cycler', {
                labels = 'PCs Only|PCs and Pets|All',
                values = 'pcsonly|pcs|all',
                baselabel = 'option_val_off',
                baseval = 'off',
                default = 'off'
            });
        end
    end
end
