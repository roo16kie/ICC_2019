
`timescale 1ns/10ps

module  CONV(
		clk,
		reset,
		busy,	
		ready,	

		iaddr,
		idata,	

	 	cwr,
	 	caddr_wr,
	 	cdata_wr,

	 	crd,
	 	caddr_rd,
	 	cdata_rd,

	 	csel
	);

	input		clk           ;
	input		reset         ;
	output	reg	busy          ;
	input		ready         ;
	output	reg [11:0]	iaddr         ;
	input	[19:0]	idata         ;
	output	 reg	cwr           ;
	output	 reg	[11:0] caddr_wr      ;
	output reg signed[19:0] 	cdata_wr      ;
	output	 reg	crd           ;
	output	reg [11:0]	caddr_rd      ;
	input	 [19:0]	cdata_rd      ;
	output	 reg [2:0]	csel          ;
	
	reg [1:0]counter_M;


	
	
	parameter IDLE = 4'd0 ;
	parameter READ = 4'd1 ;
	parameter CONV     = 4'd2      ;
	parameter RELU     = 4'd3      ;
	parameter OUT_L0     = 4'd4    ;
	parameter READ_L0     = 4'd5   ;
	parameter MAX     = 4'd6       ;
	parameter OUT_L1     = 4'd7    ;
	parameter FIN     = 4'd8       ;
	
	
	parameter K0 = 20'h0A89E ;
	parameter K1 = 20'h092D5 ;
	parameter K2 = 20'h06D43 ;
	parameter K3 = 20'h01004 ;
	parameter K4 = 20'hF8F71 ;
	parameter K5 = 20'hF6E54 ;
	parameter K6 = 20'hFA6D7 ;
	parameter K7 = 20'hFC834 ;
	parameter K8 = 20'hFAC19 ;
	
	
	reg[3:0] state , state_Next ;
	reg[3:0] counter ;
	reg[5:0] x ,y ;
	reg signed [19:0] buff [0:8] ;
	reg signed [19:0] temp_1 , temp_2 ;
	reg signed [44:0] mac ;
	wire [5:0] x_b , x_f , y_b , y_f ;
	wire signed [20:0] temp_mac ;
	reg change ;
	

	
	

	
	assign x_b = x - 6'd1 ;
	assign x_f = x + 6'd1 ;
	assign y_b = y - 6'd1 ;
	assign y_f = y + 6'd1 ;
	
	assign temp_mac = mac[35:15]+20'd1;
	
	always@(posedge clk or posedge reset)
	begin
		if(reset)
			counter_M <=2'd0;
		else if(state == READ_L0)
			counter_M <= counter_M + 2'b01;
		else if(state==OUT_L1)
			counter_M <= 2'd0 ;
	end
	
	always@(posedge clk or posedge reset)
	begin
		if(reset)
			busy <= 0 ;
		else if(ready)
			busy <= 1 ;
		else if(state==FIN)
			busy <= 0 ;
	end
	
	
	always@(posedge clk)
	begin
		if(&counter_M)
			change <= 1 ;
		else
			change <= 0 ;
	end
	
	
	always@(*)
	begin
		case(counter)
		4'd0 : temp_1 = buff[0] ;
		4'd1 : temp_1 = buff[1] ;
		4'd2 : temp_1 = buff[2] ;
		4'd3 : temp_1 = buff[3] ;
		4'd4 : temp_1 = buff[4] ;
		4'd5 : temp_1 = buff[5] ;
		4'd6 : temp_1 = buff[6] ;
		4'd7 : temp_1 = buff[7] ;
		4'd8 : temp_1 = buff[8] ;
		default : temp_1 = 20'd0 ;
		endcase
	end
	
	always@(*)
	begin
		case(counter)
		4'd0 : temp_2 = K0;
		4'd1 : temp_2 = K1;
		4'd2 : temp_2 = K2 ;
		4'd3 : temp_2 = K3 ;
		4'd4 : temp_2 = K4 ;
		4'd5 : temp_2 = K5 ;
		4'd6 : temp_2 = K6 ;
		4'd7 : temp_2 = K7 ;
		4'd8 : temp_2 = K8 ;
		default : temp_2 = 20'd0 ;
		endcase
	end
	
	always@(posedge clk or posedge reset)
	begin
		if(reset)
			mac <= 45'd0 ;
		else if(state==CONV)
		begin
			if(counter==4'd9)
			mac <= mac + {20'h01310,16'h0} ;
			else
			mac <= mac + temp_1*temp_2 ;
		end
		else if(state==READ)
			mac <= 45'd0 ;
	end
	
	
	always@(posedge clk)
	begin
		if(state==READ_L0)
			caddr_rd <= ( {y[4:0],7'd0} + {5'd0,counter_M[1],6'd0} ) + ( {5'd0,x,1'b0} + {11'd0,counter_M[0]} );
	end
	
	
	
	
	always@(posedge clk )
	begin
		if(state_Next==OUT_L0)
		begin
			if(mac[35])
			cdata_wr <= 20'd0 ;
			else
			cdata_wr <= temp_mac[20:1] ;
		end
		else if(state==READ_L0)
		begin
			if(counter_M==2'b01)
				cdata_wr <= cdata_rd ;
			else if(cdata_rd > cdata_wr)
				cdata_wr <= cdata_rd ;
		end
	end
	
	always@(posedge clk or posedge reset)
	begin
		if(reset)
			cwr <= 0 ;
		else if(state_Next==OUT_L0)
			cwr <= 1 ;
		else if(state==OUT_L1)
			cwr <= 1 ;	
		else 
			cwr <= 0 ;
	end
	
	always@(posedge clk)
	begin
		if(state_Next==OUT_L0)
			caddr_wr <= {y,x} ;
		else if(state==OUT_L1) 
			caddr_wr <= {y[4:0],x[4:0]} ;
	end
	
	always@(posedge clk or posedge reset)
	begin
		if(reset)
			csel <= 3'b000;
		else if(state_Next==OUT_L0)
			csel <= 3'b001 ;
		else if(state==READ_L0)
			csel <= 3'b001 ;
		else if(state==OUT_L1)
			csel <= 3'b011 ;
	end
	
	
	always@(posedge clk or posedge reset)
	begin
		if(reset)
			crd <= 0 ;
		else if(state==READ_L0)
			crd <= 1 ;
	end
	
	
	
	
	always@(posedge clk or posedge reset)
	begin
		if(reset)
		counter <= 4'd0 ;
		else if(counter==4'd9)
		counter <= 4'd0 ;
		else if((state==READ)||(state==CONV))
		counter <= counter + 4'd1 ;
	end
	
	always@(posedge clk or posedge reset)
	begin
		if(reset)
			state <= IDLE ;
		else 
			state <= state_Next ;
	end
	
	always@(*)
	begin
		case(state)
			IDLE: state_Next = (ready) ? READ : IDLE ;
			READ: state_Next = (counter==4'd9) ? CONV : READ ;
			CONV: state_Next = (counter==4'd9) ? RELU : CONV ;
			RELU: state_Next = OUT_L0 ;
			OUT_L0: state_Next = ((&x)&&(&y)) ? READ_L0 : READ ;
			READ_L0: state_Next = (change) ? OUT_L1 : READ_L0 ;
			OUT_L1:  state_Next = ((&x[4:0])&&(&y[4:0])) ? FIN : READ_L0 ;
			FIN:	state_Next = FIN ;
			default : state_Next = IDLE ;
		endcase
	
	end
	
	always@(posedge clk or posedge reset)
	begin
		if(reset)
		x <= 6'd0 ;
		else if(state==OUT_L0)
		begin
			if(x==6'd63)
			x <= 6'd0 ;
			else
			x <= x + 6'd1 ;
			end
		else if(state==OUT_L1)
			begin
			if(x==6'd31)
			x <= 6'd0 ;
			else
			x <= x + 6'd1 ;
			end
	end
	
	always@(posedge clk or posedge reset)
	begin
		if(reset)
		y <= 6'd0 ;
		else if(state==OUT_L0)
		begin
		if(x==6'd63)
		y <= y + 6'd1 ;
		end
		else if(state==OUT_L1)
		begin
		if(x==6'd31)
		y <= y + 6'd1 ;
		end
	end	
	
	always@(posedge clk)
	begin
		if(state==READ)
		begin
			if(counter==4'd0)
				iaddr = {y_b,x_b} ;
			if(counter==4'd1)
				iaddr = {y_b,x} ;
			if(counter==4'd2)
				iaddr = {y_b,x_f} ;
			if(counter==4'd3)
				iaddr = {y,x_b} ;
			if(counter==4'd4)
				iaddr = {y,x} ;
			if(counter==4'd5)
				iaddr = {y,x_f} ;
			if(counter==4'd6)
				iaddr = {y_f,x_b} ;
			if(counter==4'd7)
				iaddr = {y_f,x} ;
			if(counter==4'd8)
				iaddr = {y_f,x_f} ;
		end
	end
	
	always@(posedge clk or posedge reset)
	begin
		if(reset)
			buff[0] <= 20'd0 ;
		else if(state==READ)
		begin
			if(counter==4'd1)
			begin
				if((y!=0)&&(x!=0))
					buff[0] <= idata ;
				else
					buff[0] <= 20'd0 ;
			end
		end
	end
	always@(posedge clk or posedge reset)
	begin
		if(reset)
			buff[1] <= 20'd0 ;
		else if(state==READ)
		begin
			if(counter==4'd2)
			begin
				if(y!=0)
					buff[1] <= idata ;
					else
					buff[1] <= 20'd0 ;
			end
		end
	end
	always@(posedge clk or posedge reset)
	begin
		if(reset)
			buff[2] <= 20'd0 ;
		else if(state==READ)
		begin
			if(counter==4'd3)
			begin
				if((y!=0)&&(x!=6'd63))
					buff[2] <= idata ;
				else
					buff[2] <= 20'd0 ;
			end
		end
	end
	always@(posedge clk or posedge reset)
	begin
		if(reset)
			buff[3] <= 20'd0 ;
		else if(state==READ)
		begin
			if(counter==4'd4)
			begin
				if(x!=6'd0)
					buff[3] <= idata ;
				else
					buff[3] <= 20'd0 ;
			end
		end
	end
	always@(posedge clk or posedge reset)
	begin
		if(reset)
			buff[4] <= 20'd0 ;
		else if(state==READ)
		begin
			if(counter==4'd5)
					buff[4] <= idata ;
		end
	end
	always@(posedge clk or posedge reset)
	begin
		if(reset)
			buff[5] <= 20'd0 ;
		else if(state==READ)
		begin
			if(counter==4'd6)
			begin
			if(x!=6'd63)
					buff[5] <= idata ;
			else
					buff[5] <= 20'd0 ;
			end
		end
	end
	always@(posedge clk or posedge reset)
	begin
		if(reset)
			buff[6] <= 20'd0 ;
		else if(state==READ)
		begin
			if(counter==4'd7)
			begin
				if((y!=6'd63)&&(x!=6'd0))
					buff[6] <= idata ;
				else
					buff[6] <= 20'd0 ;
			end
		end
	end
	always@(posedge clk or posedge reset)
	begin
		if(reset)
			buff[7] <= 20'd0 ;
		else if(state==READ)
		begin
			if(counter==4'd8)
			begin
				if(y!=6'd63)
					buff[7] <= idata ;
			else
					buff[7] <= 20'd0 ;
			end
		end
	end
	always@(posedge clk or posedge reset)
	begin
		if(reset)
			buff[8] <= 20'd0 ;
		else if(state==READ)
		begin
			if(counter==4'd9)
			begin
			if((y!=6'd63)&&(x!=6'd63))
					buff[8] <= idata ;
			else
					buff[8] <= 20'd0 ;
			end
		end
	end
	
	
	
	
	



	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
endmodule







