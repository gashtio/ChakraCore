// -------------------------------------------------------------------------------------------------------
// Copyright (C) Microsoft. All rights reserved.
// Licensed under the MIT license. See LICENSE.txt file in the project root for full license information.
// -------------------------------------------------------------------------------------------------------

#include "unixasmmacros.inc"

    // Var arm64_GET_CURRENT_FRAME(void)
    LEAF_ENTRY arm64_GET_CURRENT_FRAME, _TEXT
        mov     x0,x29
        br      lr
    LEAF_END arm_GET_CURRENT_FRAME, _TEXT
