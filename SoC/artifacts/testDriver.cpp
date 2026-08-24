#include "xparameters.h"
#include "xil_io.h"
#include "xil_types.h"

// ---------------------------------------------------------
// Hardware addresses from xparameters.h
// ---------------------------------------------------------

#define DPU_BASE       XPAR_DPU_AXI_0_BASEADDR
#define INPUT_BASE     XPAR_INPUT_BRAM_CTRL_BASEADDR
#define OUTPUT_BASE    XPAR_OUT_BRAM_CTRL_BASEADDR
#define WEIGHT_BASE    XPAR_WEIGHT_BRAM_CTRL_BASEADDR

// ---------------------------------------------------------
// DPU AXI register map
// ---------------------------------------------------------

#define DPU_CONTROL_OFFSET   0x00
#define DPU_STATUS_OFFSET    0x04

#define DPU_START_MASK       0x00000001U

#define DPU_BUSY_MASK        0x00000001U
#define DPU_DONE_MASK        0x00000002U

#define DPU_ACT_SHIFT        3

// ---------------------------------------------------------
// Simple BRAM read/write test
// ---------------------------------------------------------

static int test_bram(UINTPTR base)
{
    const u32 test0 = 0x12345678U;
    const u32 test1 = 0xABCDEF01U;
    const u32 test2 = 0x55AA55AAU;

    Xil_Out32(base + 0x00, test0);
    Xil_Out32(base + 0x04, test1);
    Xil_Out32(base + 0x08, test2);

    u32 read0 = Xil_In32(base + 0x00);
    u32 read1 = Xil_In32(base + 0x04);
    u32 read2 = Xil_In32(base + 0x08);

    if (read0 != test0)
        return 1;

    if (read1 != test1)
        return 2;

    if (read2 != test2)
        return 3;

    return 0;
}

int main()
{
    volatile u32 status;
    int result;

    // -----------------------------------------------------
    // 1. Input BRAM
    // -----------------------------------------------------

    result = test_bram(INPUT_BASE);

    if (result != 0)
    {
        // Put breakpoint here if input BRAM fails
        while (1);
    }

    // -----------------------------------------------------
    // 2. Weight BRAM
    // -----------------------------------------------------

    result = test_bram(WEIGHT_BASE);

    if (result != 0)
    {
        // Put breakpoint here if weight BRAM fails
        while (1);
    }

    // -----------------------------------------------------
    // 3. Output BRAM
    // -----------------------------------------------------

    result = test_bram(OUTPUT_BASE);

    if (result != 0)
    {
        // Put breakpoint here if output BRAM fails
        while (1);
    }

    // -----------------------------------------------------
    // 4. Read initial DPU status
    // -----------------------------------------------------

    status = Xil_In32(DPU_BASE + DPU_STATUS_OFFSET);

    // Ideally:
    // busy = 0
    // done = 0
    //
    // Inspect "status" in the Vitis debugger.

    // -----------------------------------------------------
    // 5. Select activation mode 0
    // -----------------------------------------------------

    u32 control = (0U << DPU_ACT_SHIFT);

    Xil_Out32(
        DPU_BASE + DPU_CONTROL_OFFSET,
        control
    );

    // Read control register back
    u32 control_readback =
        Xil_In32(DPU_BASE + DPU_CONTROL_OFFSET);

    if (control_readback != control)
    {
        // AXI control register failure
        while (1);
    }

    // -----------------------------------------------------
    // 6. Pulse START
    // -----------------------------------------------------

    Xil_Out32(
        DPU_BASE + DPU_CONTROL_OFFSET,
        control | DPU_START_MASK
    );

    // Keep start asserted briefly through a few AXI accesses
    status = Xil_In32(DPU_BASE + DPU_STATUS_OFFSET);

    // Deassert start
    Xil_Out32(
        DPU_BASE + DPU_CONTROL_OFFSET,
        control
    );

    // -----------------------------------------------------
    // 7. Poll status
    //
    // This is intentionally bounded so a hardware problem
    // does not hang the CPU forever.
    // -----------------------------------------------------

    const u32 TIMEOUT = 10000000U;

    u32 count = 0;

    while (count < TIMEOUT)
    {
        status = Xil_In32(DPU_BASE + DPU_STATUS_OFFSET);

        if (status & DPU_DONE_MASK)
            break;

        count++;
    }

    if ((status & DPU_DONE_MASK) == 0)
    {
        // DPU never asserted done.
        // Put breakpoint here and inspect:
        // status
        // count
        while (1);
    }

    // -----------------------------------------------------
    // 8. Read a few output BRAM locations
    // -----------------------------------------------------

    volatile u32 output0 = Xil_In32(OUTPUT_BASE + 0x00);
    volatile u32 output1 = Xil_In32(OUTPUT_BASE + 0x04);
    volatile u32 output2 = Xil_In32(OUTPUT_BASE + 0x08);
    volatile u32 output3 = Xil_In32(OUTPUT_BASE + 0x0C);

    // Put breakpoint here and inspect output0-output3.

    while (1)
    {
        // Successful stopping point
    }

    return 0;
}