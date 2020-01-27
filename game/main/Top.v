`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2016/10/17 12:25:41
// Design Name: 
// Module Name: Top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Top(
	input clk,
	input rstn,
	input [15:0]SW,
	input wire ps2_clk,	//ps2 clock
	input wire ps2_data, 
	output hs,
	output vs,
	output [3:0] r,
	output [3:0] g,
	output [3:0] b,
	output SEGLED_CLK,
	output SEGLED_CLR,
	output SEGLED_DO,
	output SEGLED_PEN,
   output LED_CLK,
	output LED_CLR,
	output LED_DO,
	output LED_PEN,
	inout [4:0]BTN_X,
	inout [3:0]BTN_Y,
	output buzzer
    );
	
	// 输入模块
	reg [31:0]clkdiv;
	wire [9:0] data;
	always@(posedge clk) begin
		clkdiv <= clkdiv + 1'b1;
	end
	
	wire clock;
	clk_100ms c0 (
    .clk(clk), 
    .clk_100ms(clock)
    );
	
	assign buzzer = 1'b1;
	wire [15:0] SW_OK;
	
	AntiJitter #(4) a0[15:0](.clk(clkdiv[15]), .I(SW), .O(SW_OK));
	
	wire [4:0] keyCode;
	wire keyReady;
	
	ps2_ver2 v2(.clk(clk),.rst(),.ps2_clk(ps2_clk),.ps2_data(ps2_data),.data_out(data),.ready());//use the ps2_ver2 block
	Keypad k0 (.clk(clkdiv[15]), .keyX(BTN_Y), .keyY(BTN_X), .keyCode(keyCode), .ready(keyReady));
	
	// 数据初始化模块
	parameter desk_4_x1 = 160;
	parameter desk_4_x2 = 280;
	parameter desk_4_y1 = 100;
	parameter desk_4_y2 = 220;
	
	parameter desk_2_x1 = 230;
	parameter desk_2_x2 = 350;
	parameter desk_2_y1 = 250;
	parameter desk_2_y2 = 370;
	
	parameter desk_3_x1 = 180;
	parameter desk_3_x2 = 300;
	parameter desk_3_y1 = 360;
	parameter desk_3_y2 = 480;
	
	parameter desk_1_x1 = 320;
	parameter desk_1_x2 = 440;
	parameter desk_1_y1 = 320;
	parameter desk_1_y2 = 440;
	
	parameter desk_5_x1 = 420;
	parameter desk_5_x2 = 540;
	parameter desk_5_y1 = 160;
	parameter desk_5_y2 = 280;
	
	reg [1:0] life_1 = 2'b00;
	reg [1:0] life_2 = 2'b00;
	reg [1:0] life_3 = 2'b00;
	reg [1:0] life_4 = 2'b00;
	reg [1:0] life_5 = 2'b00;
	
	// 七段数码管显示模块
	wire [31:0] segTestData;
	wire [3:0]sout;
	reg [3:0] speed2 = 4'd2;
	reg [3:0] speed1 = 4'd2;
	
   Seg7Device segDevice(.clkIO(clkdiv[3]), .clkScan(clkdiv[15:14]), .clkBlink(clkdiv[25]),
		.data(segTestData), .point(8'h0), .LES(8'h0),
		.sout(sout));
	
	assign SEGLED_CLK = sout[3];
	assign SEGLED_DO = sout[2];
	assign SEGLED_PEN = sout[1];
	assign SEGLED_CLR = sout[0];
 	
	
	// 核心控制模块
	// stu
	reg [9:0] x;
	reg [8:0] y;
	
	reg [9:0] xs;
	reg [8:0] ys;
	
	//book
	reg [9:0] x0;
	reg [8:0] y0;
	reg b0 = 1'b0;
	reg [9:0] xs0;
	reg [8:0] ys0;
	reg bs0 = 1'b0;
	
	// status
	reg walk ;
	reg ahead ; 
	reg walks ;
	reg aheads ;
	
 	reg [11:0] vga_data;
 	wire [9:0] col_addr;
 	wire [8:0] row_addr;
	wire [19:0] x_sqr, y_sqr, r_sqr;
	
	vgac v0 (
		.vga_clk(clkdiv[1]), .clrn(SW_OK[0]), .d_in(vga_data), .row_addr(row_addr), .col_addr(col_addr), .r(r), .g(g), .b(b), .hs(hs), .vs(vs)
	);
	
	reg wasReady;
	reg [9:0] radius = 10'd15;
	
	always @(posedge clk) begin
		if (!rstn) begin
			x <= 10'd120;
			y <= 9'd20;
			radius <= 10'd15;
			walk = 1'b1;
			ahead = 1'b1;
			score = 4'd0;
			xs <= 10'd480;
			ys <= 9'd20;
			walks = 1'b1;
			aheads = 1'b0;
			scores = 4'd0;
		end else begin
			wasReady <= keyReady;
			if (!wasReady&&keyReady) begin
				case (keyCode)
					5'hc: begin
						walk = ~walk;	//walk = ~walk;
						b0 = ~b0;
						x0 <= x ;
						y0 <= y + 9'd50;
					end
					5'hf:begin
						walks = ~walks;	//walk = ~walk;
						bs0 = ~bs0;
						xs0 <= xs ;
						ys0 <= ys + 9'd50;
					end
					5'h13: begin
						walk = 1'b1;
						b0 = 1'b0;
					end
					//5'h9: y <= y - 9'd20;
					5'h10: begin
						walks = 1'b1;
						bs0 = 1'b0;
					end
					default: ;
				endcase


		// lc-S 23-W  ld-D  lb-E	6b下  74上  75右  72左
				if (clock && data[7:0]==8'h1c && data[8] == 0)	begin
						walk = ~walk;	//walk = ~walk;
						b0 = ~b0;
						x0 <= x ;
						y0 <= y + 9'd30;
						score = score + 3;
				end
			
			end
			
			if (walk && clock) begin
				if (ahead) x <= x + speed1;
				else x <= x - speed1;
			end
			
			if (walks && clock) begin
				if (aheads) xs <= xs + speed2;
				else xs <= xs - speed2;
			end
			
			// 碰撞检测
			if (!walk) begin
				if (!life_1 && (x0 > desk_1_x1 - 30 && x0 < desk_1_x1 + 30 
							&& y0 > desk_1_y1 && y0 < desk_1_y2) )
					begin
							walk = 1'b1;
							b0 = 1'b0;	
							life_1 = 2'd1;
							score = score + 2;
					end
				if (!life_2 && (x0 > desk_2_x1 - 30 && x0 < desk_2_x1 + 30 
							&& y0 > desk_2_y1 && y0 < desk_2_y2) )
					begin
							walk = 1'b1;
							b0 = 1'b0;	
							life_2 = 2'd1;
							score = score + 2;
					end
				if (!life_3 && (x0 > desk_3_x1 - 30 && x0 < desk_3_x1 + 30 
							&& y0 > desk_3_y1 && y0 < desk_3_y2) )
					begin
							walk = 1'b1;
							b0 = 1'b0;	
							life_3 = 2'd1;
							score = score + 2;
					end
				if (!life_4 && (x0 > desk_4_x1 - 30 && x0 < desk_4_x1 + 30 
							&& y0 > desk_4_y1 && y0 < desk_4_y2) )
					begin
							walk = 1'b1;
							b0 = 1'b0;	
							life_4 = 2'd1;
							score = score + 2;
					end
				if (!life_5 && (x0 > desk_5_x1 - 30 && x0 < desk_5_x1 + 30 
							&& y0 > desk_5_y1 && y0 < desk_5_y2) )
					begin
							walk = 1'b1;
							b0 = 1'b0;	
							life_5 = 2'd1;
							score = score + 2;
					end
			end
				
			if (!walks) begin
				if (!life_1 && (xs0 > desk_1_x1 - 30 && xs0 < desk_1_x1 + 30 
							&& ys0 > desk_1_y1 && ys0 < desk_1_y2) )
					begin
							walks = 1'b1;
							bs0 = 1'b0;	
							life_1 = 2'd2;
							scores = scores + 2;
					end
				if (!life_2 && (xs0 > desk_2_x1 - 30 && xs0 < desk_2_x1 + 30 
							&& ys0 > desk_2_y1 && ys0 < desk_2_y2) )
					begin
							walks = 1'b1;
							bs0 = 1'b0;	
							life_2 = 2'd2;
							scores = scores + 2;
					end
				if (!life_3 && (xs0 > desk_3_x1 - 30 && xs0 < desk_3_x1 + 30 
							&& ys0 > desk_3_y1 && ys0 < desk_3_y2) )
					begin
							walks = 1'b1;
							bs0 = 1'b0;	
							life_3 = 2'd2;
							scores = scores + 2;
					end
				if (!life_4 && (xs0 > desk_4_x1 - 30 && xs0 < desk_4_x1 + 30 
							&& ys0 > desk_4_y1 && ys0 < desk_4_y2) )
					begin
							walks = 1'b1;
							bs0 = 1'b0;	
							life_4 = 2'd2;
							scores = scores + 2;
					end
				if (!life_5 && (xs0 > desk_5_x1 - 30 && xs0 < desk_5_x1 + 30 
							&& ys0 > desk_5_y1 && ys0 < desk_5_y2) )
					begin
							walks = 1'b1;
							bs0 = 1'b0;	
							life_5 = 2'd2;
							scores = scores + 2;
					end
			end				
					
			if (!walk && clock) begin
				b0 = 1'b1;
				y0 <= y0 + 9'd10;				
			end
			if (!walks && clock) begin
				bs0 = 1'b1;
				ys0 <= ys0 + 9'd10;				
			end
			
			if (!walks && ys0 > 10'd460) begin
				walks = 1'b1;
				bs0 = 1'b0;
			end
							
			if (!walk && y0 > 10'd460) begin
				walk = 1'b1;
				b0 = 1'b0;
			end
				
			if (ahead && x > 10'd520 ) ahead = !ahead;
			if ( !ahead && x < 10'd120) ahead = ~ahead;
			
			if (aheads && xs > 10'd520 ) aheads = !aheads;
			if ( !aheads && xs < 10'd120) aheads = ~aheads;
				
		end
	end
	
		always @(posedge clkdiv[20]) begin
		
		if (data[7:0]==8'h1c && data[8] == 0 )
			begin
				speed1 = 1;
			end
		if (data[7:0]==8'h23 && data[8] == 0 ) begin
				speed1 = 2;
			end
		if (data[7:0]==8'h1d && data[8] == 0 )
			begin
				speed1 = 3;
			end
		if (data[7:0]==8'h1b && data[8] == 0 ) begin
				speed1 = 4;
			end
		if (data[7:0]==8'h6b && data[8] == 0 )
			begin
				speed2 = 1;
			end
		if (data[7:0]==8'h74 && data[8] == 0 ) begin
				speed2 = 2;
			end
		if (data[7:0]==8'h75 && data[8] == 0 )
			begin
				speed2 = 3;
			end
		if (data[7:0]==8'h72 && data[8] == 0 ) begin
				speed2 = 4;
			end
	end
		
	
	assign x_sqr = (x - col_addr) * (x - col_addr);
	assign y_sqr = (y - row_addr) * (y - row_addr);
	assign r_sqr = radius * radius;
	
		
	reg [3:0] score;
	reg [3:0] scores;
	wire [11:0] spob;
	reg [18:0] bg1;
	wire [11:0] stu;
	reg [18:0] stul;
	wire [11:0] son;
	reg [18:0] sonl;
	wire [11:0] books;
	reg [18:0] booksl;
	wire [11:0] book;
	reg [18:0] bookl;
	wire [11:0] desk_1;
	wire [11:0] desk_book_1;
	reg [18:0] deskl_1;
	wire [11:0] desk_2;
	wire [11:0] desk_book_2;
	reg [18:0] deskl_2;
	wire [11:0] desk_3;
	wire [11:0] desk_book_3;
	reg [18:0] deskl_3;
	wire [11:0] desk_4;
	wire [11:0] desk_book_4;
	reg [18:0] deskl_4;
	wire [11:0] desk_5;
	wire [11:0] desk_book_5;
	wire [11:0] desk_books_1;
	wire [11:0] desk_books_2;
	wire [11:0] desk_books_3;
	wire [11:0] desk_books_4;
	wire [11:0] desk_books_5;
	
	reg [18:0] deskl_5;
	wire [11:0] start;
	reg [18:0] startl;
	wire [11:0] finish;
	reg [18:0] finishl;
	wire [11:0] finish0;
	reg [18:0] finishl0;

	
	background m0 (.addra(bg1),.douta(spob),.clka(clkdiv[1]));   
	girlwithback m1 (.addra(stul),.douta(stu),.clka(clkdiv[1]));
	newbook m2 (.addra(bookl),.douta(book),.clka(clkdiv[1])); //待修改，新书
	childnew s1 (.addra(sonl),.douta(son),.clka(clkdiv[1]));
	book s2 (.addra(booksl),.douta(books),.clka(clkdiv[1]));	
	desk m3 (.addra(deskl_1),.douta(desk_1),.clka(clkdiv[1]));
	deskwithbook m5 (.addra(deskl_1),.douta(desk_books_1),.clka(clkdiv[1]));
	desk m6 (.addra(deskl_2),.douta(desk_2),.clka(clkdiv[1]));
	deskwithbook m7 (.addra(deskl_2),.douta(desk_books_2),.clka(clkdiv[1]));
	desk m8 (.addra(deskl_3),.douta(desk_3),.clka(clkdiv[1]));
	deskwithbook m9 (.addra(deskl_3),.douta(desk_books_3),.clka(clkdiv[1]));
	desk m10 (.addra(deskl_4),.douta(desk_4),.clka(clkdiv[1]));
	deskwithbook m11 (.addra(deskl_4),.douta(desk_books_4),.clka(clkdiv[1]));
	desk m12 (.addra(deskl_5),.douta(desk_5),.clka(clkdiv[1]));
	deskwithbook m13 (.addra(deskl_5),.douta(desk_books_5),.clka(clkdiv[1]));
	beginpage m4 (.addra(startl),.douta(start),.clka(clkdiv[1]));
	new_girlendpage e1 (.addra(finishl),.douta(finish),.clka(clkdiv[1]));
	boyendpage e2 (.addra(finishl0),.douta(finish0),.clka(clkdiv[1]));
	
	newdesk d5 (.addra(deskl_1),.douta(desk_book_1),.clka(clkdiv[1]));
	newdesk d6 (.addra(deskl_2),.douta(desk_book_2),.clka(clkdiv[1]));		// 待修改，新书+桌子
	newdesk d7 (.addra(deskl_3),.douta(desk_book_3),.clka(clkdiv[1]));
	newdesk d8 (.addra(deskl_4),.douta(desk_book_4),.clka(clkdiv[1]));
	newdesk d9 (.addra(deskl_5),.douta(desk_book_5),.clka(clkdiv[1]));

	
	always@(*) begin
		bg1 <= (col_addr >= 0 && col_addr <= 639 && row_addr >= 0 && row_addr <= 479)? (479-row_addr)*640+col_addr:0;
		startl <= (col_addr >= 0 && col_addr <= 639 && row_addr >= 0 && row_addr <= 479)? (479-row_addr)/2*320+col_addr/2:0;
		finishl <= (col_addr >= 0 && col_addr <= 639 && row_addr >= 0 && row_addr <= 479)? (479-row_addr)/2*320+col_addr/2:0;
		finishl0 <= (col_addr >= 0 && col_addr <= 639 && row_addr >= 0 && row_addr <= 479)? (479-row_addr)/2*320+col_addr/2:0;
		sonl <= (col_addr >= xs && col_addr <= xs+59 && row_addr >= ys && row_addr <= ys+79)? (79-(row_addr-ys))*60+col_addr-xs:0;
		booksl <= (col_addr >= xs0 && col_addr <= xs0+79 && row_addr >= ys0 && row_addr <= ys0+79)? (79-(row_addr-ys0))*80+col_addr-xs0:0;
		stul <= (col_addr >= x && col_addr <= x+59 && row_addr >= y && row_addr <= y+79)? (79-(row_addr-y))*60+col_addr-x:0;
		bookl <= (col_addr >= x0 && col_addr <= x0+79 && row_addr >= y0 && row_addr <= y0+79)? (79-(row_addr-y0))*80+col_addr-x0:0;
		deskl_1 <= (col_addr >= desk_1_x1 && col_addr < desk_1_x2 && row_addr >= desk_1_y1 && row_addr < desk_1_y2)? (119-(row_addr-desk_1_y1))*120+col_addr-desk_1_x1:0;
		deskl_2 <= (col_addr >= desk_2_x1 && col_addr < desk_2_x2 && row_addr >= desk_2_y1 && row_addr < desk_2_y2)? (119-(row_addr-desk_2_y1))*120+col_addr-desk_2_x1:0;
		deskl_3 <= (col_addr >= desk_3_x1 && col_addr < desk_3_x2 && row_addr >= desk_3_y1 && row_addr < desk_3_y2)? (119-(row_addr-desk_3_y1))*120+col_addr-desk_3_x1:0;
		deskl_4 <= (col_addr >= desk_4_x1 && col_addr < desk_4_x2 && row_addr >= desk_4_y1 && row_addr < desk_4_y2)? (119-(row_addr-desk_4_y1))*120+col_addr-desk_4_x1:0;
		deskl_5 <= (col_addr >= desk_5_x1 && col_addr < desk_5_x2 && row_addr >= desk_5_y1 && row_addr < desk_5_y2)? (119-(row_addr-desk_5_y1))*120+col_addr-desk_5_x1:0;
		
		if (SW[1]) // 开始界面
			vga_data <= start[11:0];
		else if (SW[3])
			vga_data <= finish[11:0];
		else if (SW[4])
			vga_data <= finish0[11:0];
		else if (score + scores == 4'd10 && score > scores)
			vga_data <= finish[11:0];
		else if (score + scores == 4'd10 && score < scores)
			vga_data <= finish0[11:0];
		else begin	//游戏界面
			if ((col_addr >= x && col_addr <= x+59 && row_addr >= y && row_addr <= y+79))
				vga_data <= stu[11:0];	//学生
			else 	if ((col_addr >= xs && col_addr <= xs+59 && row_addr >= ys && row_addr <= ys+79))
				vga_data <= son[11:0];	//学生
			else if (!walks && (col_addr >= xs0 && col_addr <= xs0+79 && row_addr >= ys0 && row_addr <= ys0+79))
					vga_data <= books[11:0];			
			else if (!walk && (col_addr >= x0 && col_addr <= x0+79 && row_addr >= y0 && row_addr <= y0+79))
					vga_data <= book[11:0];			

			else if ( col_addr > desk_1_x1 && col_addr < desk_1_x2 
						&& row_addr > desk_1_y1 && row_addr < desk_1_y2 )	//桌子1
				begin 
					if (!life_1) vga_data <= desk_1[11:0];
					else if (life_1 == 1) vga_data <= desk_book_1[11:0];
					else if (life_1 == 2) vga_data <= desk_books_1[11:0];
				end

			else if ( col_addr > desk_2_x1 && col_addr < desk_2_x2 
						&& row_addr > desk_2_y1 && row_addr < desk_2_y2 )	//桌子2
				begin 
					if (!life_2) vga_data <= desk_2[11:0];
					else if (life_2 == 1) vga_data <= desk_book_2[11:0];
					else if (life_2 == 2) vga_data <= desk_books_2[11:0];
				end	

			else if ( col_addr > desk_3_x1 && col_addr < desk_3_x2 
						&& row_addr > desk_3_y1 && row_addr < desk_3_y2 )	//桌子3
				begin 
					if (!life_3) vga_data <= desk_3[11:0];
					else if (life_3 == 1) vga_data <= desk_book_3[11:0];
					else if (life_3 == 2) vga_data <= desk_books_3[11:0];
				end
			else if ( col_addr > desk_4_x1 && col_addr < desk_4_x2 
						&& row_addr > desk_4_y1 && row_addr < desk_4_y2 )	//桌子4
				begin 
					if (!life_4) vga_data <= desk_4[11:0];
					else if (life_4 == 1) vga_data <= desk_book_4[11:0];
					else if (life_4 == 2) vga_data <= desk_books_4[11:0];					
				end
			else if ( col_addr > desk_5_x1 && col_addr < desk_5_x2 
						&& row_addr > desk_5_y1 && row_addr < desk_5_y2 )	//桌子5
				begin 
					if (!life_5) vga_data <= desk_5[11:0];
					else if (life_5 == 1) vga_data <= desk_book_5[11:0];
					else if (life_5 == 2) vga_data <= desk_books_5[11:0];
				end
									
			else 
				vga_data <=  spob[11:0];
		end
	end
	
	assign segTestData = {speed1,speed2,8'b0,9'b0,score,scores};
	wire [15:0] ledData;
	assign ledData = SW_OK;
	
	ShiftReg #(.WIDTH(16)) ledDevice (.clk(clkdiv[3]), .pdata(~ledData), .sout({LED_CLK,LED_DO,LED_PEN,LED_CLR}));
endmodule
