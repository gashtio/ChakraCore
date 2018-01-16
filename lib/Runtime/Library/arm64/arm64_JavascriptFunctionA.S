;-------------------------------------------------------------------------------------------------------
; Copyright (C) Coherent Labs AD. All rights reserved.
; Licensed under the MIT license.
;-------------------------------------------------------------------------------------------------------

#include "unixasmmacros.inc"

;.global C_FUNC(_ZN2Js18JavascriptFunction24DeferredDeserializeThunkEPNS_16RecyclableObjectENS_8CallInfoEz)
;.global C_FUNC(_ZN2Js18JavascriptFunction20DeferredParsingThunkEPNS_16RecyclableObjectENS_8CallInfoEz)
;.global C_FUNC(arm64_CallFunction)

;Var arm64_CallFunction(JavascriptFunction* function, CallInfo info, uint argCount, Var* values, JavascriptMethod entryPoint)
    NESTED_ENTRY arm64_CallFunction, _TEXT, NoHandler

    PROLOG_SAVE_REG_PAIR fp, lr, -16            ; save fp/lr (implicitly saves SP in FP)

    mov     x8, x4                              ; copy entry point to x8
    mov     x9, x3                              ; copy values pointer to x9

#if 0 && _CONTROL_FLOW_GUARD
    mov     x15, x4                             ; __guard_check_icall_fptr requires the call target in x15
    adrp    x16, __guard_check_icall_fptr       ;
    ldr     x16, [x16, __guard_check_icall_fptr]; fetch address of guard check handler
    blr     x16                                 ; call it
#endif

    subs    x5, x2, #6                          ; more than 6 parameters?
    bgt     LOCAL_LABEL(StackAlloc)                          ; if so, allocate necessary stack

    adr     x5, LOCAL_LABEL(CopyZero)                        ; get bottom of parameter copy loop
    sub     x5, x5, x2, lsl #2                  ; compute address of where to start
    br      x5                                  ; branch there
LOCAL_LABEL(CopyAll):
    ldr     x7, [x9, #40]                       ; load remaining 6 registers here
    ldr     x6, [x9, #32]                       ;
    ldr     x5, [x9, #24]                       ;
    ldr     x4, [x9, #16]                       ;
    ldr     x3, [x9, #8]                        ;
    ldr     x2, [x9, #0]                        ;
LOCAL_LABEL(CopyZero):
    ; push arguments on stack as well, as some functions rely on
    ; address computation relative to the next frame's frame pointer.
    ; EPILOG_STACK_RESTORE will clean up afterwards
    sub     sp, sp, #64
    stp     x0, x1, [sp]
    stp     x2, x3, [sp, #16]
    stp     x4, x5, [sp, #32]
    stp     x6, x7, [sp, #48]

    blr     x8                                  ; call saved entry point

    EPILOG_STACK_RESTORE                        ; explicitly restore sp
    EPILOG_RESTORE_REG_PAIR fp, lr, 16          ; restore FP/LR
    EPILOG_RETURN                               ; return

LOCAL_LABEL(StackAlloc):
    add     x15, x5, #1                         ; round (param_count - 6) up by 1
    lsr     x15, x15, #1                        ; divide by 2
    // bl      __chkstk                            ; ensure stack is allocated
    sub     sp, sp, x15, lsl #4                 ; then allocate the space
    add     x3, x3, #48                         ; use x3 = source
    mov     x4, sp                              ; use x4 = dest
LOCAL_LABEL(CopyLoop):
    subs    x5, x5, #1                          ; decrement param count by 1
    ldr     x7, [x3], #8                        ; read param from source
    str     x7, [x4], #8                        ; store param to dest
    bne     LOCAL_LABEL(CopyLoop)                            ; loop until all copied
    b       LOCAL_LABEL(CopyAll)                             ; jump ahead to copy all 6 remaining parameters

    NESTED_END arm64_CallFunction, _TEXT


;Var Js:JavascriptFunction::DeferredDeserializeThunk(function, info, values[0], values[1], ..., values[n-2], values[n-1])
    NESTED_ENTRY _ZN2Js18JavascriptFunction24DeferredDeserializeThunkEPNS_16RecyclableObjectENS_8CallInfoEz, _TEXT, NoHandler

    PROLOG_SAVE_REG_PAIR fp, lr, -80  ; save parameter registers
    stp     x0, x1, [sp, #16]
    stp     x2, x3, [sp, #32]
    stp     x4, x5, [sp, #48]
    stp     x6, x7, [sp, #64]

    bl      C_FUNC(_ZN2Js18JavascriptFunction19DeferredDeserializeEPNS_14ScriptFunctionE) ; retrieve entrypoint
    mov     x16, x0                     ; back up entryPoint in x16

    ldp     x6, x7, [sp, #64]
    ldp     x4, x5, [sp, #48]
    ldp     x2, x3, [sp, #32]
    ldp     x0, x1, [sp, #16]
    EPILOG_RESTORE_REG_PAIR fp, lr, 80
    br x16                   ; tail call to new entryPoint

    NESTED_END _ZN2Js18JavascriptFunction24DeferredDeserializeThunkEPNS_16RecyclableObjectENS_8CallInfoEz, _TEXT


;Var Js:JavascriptFunction::DeferredParsingThunk(function, info, values[0], values[1], ..., values[n-2], values[n-1])
    NESTED_ENTRY _ZN2Js18JavascriptFunction20DeferredParsingThunkEPNS_16RecyclableObjectENS_8CallInfoEz, _TEXT, NoHandler

    PROLOG_SAVE_REG_PAIR fp, lr, -80
    stp     x0, x1, [sp, #16]
    stp     x2, x3, [sp, #32]
    stp     x4, x5, [sp, #48]
    stp     x6, x7, [sp, #64]

    ; Pass the address of the function at the saved x0
    mov     x0, sp
    add     x0, x0, #16                 ; 16 is subtracted from the stack pointer when the a function is called, add it back here.
    bl      C_FUNC(_ZN2Js18JavascriptFunction13DeferredParseEPPNS_14ScriptFunctionE) ; retrieve entrypoint
    mov     x16, x0                     ; back up entryPoint in x16

    ldp     x6, x7, [sp, #64]
    ldp     x4, x5, [sp, #48]
    ldp     x2, x3, [sp, #32]
    ldp     x0, x1, [sp, #16]
    EPILOG_RESTORE_REG_PAIR fp, lr, 80
    br x16                   ; tail call to new entryPoint

    NESTED_END _ZN2Js18JavascriptFunction20DeferredParsingThunkEPNS_16RecyclableObjectENS_8CallInfoEz, _TEXT
