`timescale 1ps/1ps

`define PRIM_UNIT_NULL_DELAY #0
`define PRIM_UNIT_COMB_DELAY #1
`define PRIM_UNIT_SEQ_DELAY  #1
`define PRIM_UNIT_CLK_DELAY  #1

module sky130_fd_sc_hd__udp_dff$NSR (
    Q    ,
    SET  ,
    RESET,
    CLK_N,
    D
);

   output Q;
   input SET;
   input RESET;
   input CLK_N;
   input D;

   reg _Q;

   always @(negedge CLK_N or posedge SET or posedge RESET)
       if (SET)
           _Q <= 1'b1;
       else if (RESET)
           _Q <= 1'b0;
       else
           _Q <= D;

    assign `PRIM_UNIT_SEQ_DELAY Q = _Q;

endmodule

module sky130_fd_sc_hd__udp_dff$P (
    Q  ,
    D  ,
    CLK
);

    output Q;
    input D;
    input CLK;

    reg _Q;

    always @(posedge CLK)
        _Q <= D;

    assign `PRIM_UNIT_SEQ_DELAY Q = _Q;

endmodule

module sky130_fd_sc_hd__udp_dff$PR (
    Q  ,
    D  ,
    CLK,
    RESET
);

    output Q;
    input D;
    input CLK;
    input RESET;

    reg _Q;

    always @(posedge CLK or posedge RESET)
        if (RESET)
            _Q <= 1'b0;
        else
            _Q <= D;

    assign `PRIM_UNIT_SEQ_DELAY Q = _Q;

endmodule

module sky130_fd_sc_hd__udp_dff$PS (
    Q  ,
    D  ,
    CLK,
    SET
);

   output Q;
   input D;
   input CLK;
   input SET;

   reg _Q;

   always @(posedge CLK or posedge SET)
       if (SET)
           _Q <= 1'b1;
       else
           _Q <= D;

    assign `PRIM_UNIT_SEQ_DELAY Q = _Q;

endmodule


module sky130_fd_sc_hd__udp_dlatch$lP (
    Q    ,
    D    ,
    GATE
);

    output Q;
    input D;
    input GATE;

    reg _Q;

    always @(*)
        if (GATE)
            _Q <= D;

    assign `PRIM_UNIT_SEQ_DELAY Q = _Q;

endmodule

module sky130_fd_sc_hd__udp_dlatch$P (
    Q    ,
    D    ,
    GATE
);

    output Q;
    input D;
    input GATE;

    reg _Q;

    always @(*)
        if (GATE)
            _Q <= D;

    assign `PRIM_UNIT_SEQ_DELAY Q = _Q;

endmodule

module sky130_fd_sc_hd__udp_dlatch$PR (
    Q    ,
    D    ,
    GATE ,
    RESET
);

    output Q;
    input D;
    input GATE;
    input RESET;

    reg _Q;

    always @(*)
        if (RESET)
            _Q <= 1'b0;
        else if (GATE)
            _Q <= D;

    assign `PRIM_UNIT_SEQ_DELAY Q = _Q;

endmodule

module sky130_fd_sc_hd__udp_mux_2to1 (
    X ,
    A0,
    A1,
    S
); 

    output X ;
    input  A0;
    input  A1;
    input  S ;

    reg _X;

    always @(*)
        case (S)
            1'b0: _X = A0;
            1'b1: _X = A1;
            default: _X = 1'bx;
        endcase

    assign `PRIM_UNIT_SEQ_DELAY X = _X;

endmodule

module sky130_fd_sc_hd__udp_mux_2to1_N (
    Y ,
    A0,
    A1,
    S
); 

    output Y ;
    input  A0;
    input  A1;
    input  S ;

    reg _Y;

    always @(*)
        case (S)
            1'b0: _Y = !A0;
            1'b1: _Y = !A1;
            default: _Y = 1'bx;
        endcase

    assign `PRIM_UNIT_SEQ_DELAY Y = _Y;

endmodule

module sky130_fd_sc_hd__udp_mux_4to2 (
    X ,
    A0,
    A1,
    A2,
    A3,
    S0,
    S1
); 

    output X ;
    input  A0;
    input  A1;
    input  A2;
    input  A3;
    input  S0;
    input  S1;

    reg _X;

    always @(*)
        case ({S1, S0})
            2'b00: _X = A0;
            2'b01: _X = A1;
            2'b10: _X = A2;
            2'b11: _X = A3;
            default: _X = 1'bx;
        endcase

    assign `PRIM_UNIT_SEQ_DELAY X = _X;

endmodule

