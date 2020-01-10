#include "ruby.h"
#include "extconf.h"

VALUE rb_alpha_vantage() {
	return rb_str_new_cstr("KEY HERE");
}

void Init_api_ext(){
	VALUE mod = rb_define_module("ApiExt");
	
	rb_define_method(mod, "alpha_vantage", rb_alpha_vantage, 0);
}