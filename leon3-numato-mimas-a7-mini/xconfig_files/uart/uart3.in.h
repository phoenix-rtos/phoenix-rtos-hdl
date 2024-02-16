#ifndef CONFIG_UART3_ENABLE
#define CONFIG_UART3_ENABLE 0
#endif

#if defined CONFIG_UA3_FIFO1
#define CFG_UA3_FIFO 1
#elif defined CONFIG_UA3_FIFO2
#define CFG_UA3_FIFO 2
#elif defined CONFIG_UA3_FIFO4
#define CFG_UA3_FIFO 4
#elif defined CONFIG_UA3_FIFO8
#define CFG_UA3_FIFO 8
#elif defined CONFIG_UA3_FIFO16
#define CFG_UA3_FIFO 16
#elif defined CONFIG_UA3_FIFO32
#define CFG_UA3_FIFO 32
#else
#define CFG_UA3_FIFO 1
#endif

