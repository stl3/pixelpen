#include "PixelPenCPP.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/godot.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <queue>

using namespace godot;


void PixelPenCPP::_bind_methods(){
    ClassDB::bind_method(D_METHOD("version"), &PixelPenCPP::version);
    ClassDB::bind_method(D_METHOD("get_mask_flood", "started_point", "p_color_map", "mask_margin", "grow_only_along_axis"), &PixelPenCPP::get_mask_flood);
    ClassDB::bind_method(D_METHOD("get_mask_used_rect", "mask"), &PixelPenCPP::get_mask_used_rect);
    ClassDB::bind_method(D_METHOD("coor_inside_canvas", "x", "y", "size", "mask"), &PixelPenCPP::coor_inside_canvas);
    ClassDB::bind_method(D_METHOD("get_color_map_with_mask", "mask", "p_color_map"), &PixelPenCPP::get_color_map_with_mask);
    ClassDB::bind_method(D_METHOD("empty_index_on_color_map", "mask", "p_color_map"), &PixelPenCPP::empty_index_on_color_map);
    ClassDB::bind_method(D_METHOD("blit_color_map", "src_map", "mask", "offset", "p_color_map"), &PixelPenCPP::blit_color_map);
    ClassDB::bind_method(D_METHOD("switch_palette", "palette_index_a", "palette_index_b", "p_color_map"), &PixelPenCPP::switch_palette);
    ClassDB::bind_method(D_METHOD("switch_color", "palette_index_a", "palette_index_b", "p_color_map"), &PixelPenCPP::switch_color);
    ClassDB::bind_method(D_METHOD("swap_palette", "old_palette", "new_palette", "p_color_map"), &PixelPenCPP::swap_palette);
    ClassDB::bind_method(D_METHOD("move_shift", "direction", "p_image"), &PixelPenCPP::move_shift);
    ClassDB::bind_method(D_METHOD("blend", "target_image", "src_image", "offset"), &PixelPenCPP::blend);
    ClassDB::bind_method(D_METHOD("import_image", "layer_image", "imported_image", "palette"), &PixelPenCPP::import_image);
    ClassDB::bind_method(D_METHOD("get_image", "palette_color", "p_color_map", "mipmap"), &PixelPenCPP::get_image);
    ClassDB::bind_method(D_METHOD("get_image_with_mask", "palette_color", "p_color_map" , "mask", "mipmap"), &PixelPenCPP::get_image_with_mask);
}


PixelPenCPP::PixelPenCPP(){
}

PixelPenCPP::~PixelPenCPP(){
}


String PixelPenCPP::version(){
    return "v0.0.1.alpha_build_2";
}


Ref<Image> PixelPenCPP::get_mask_flood(Vector2i started_point, const Ref<Image>  &p_color_map, Vector2i mask_margin = Vector2i(1, 1), const bool grow_only_along_axis = false){
    Vector2i canvas_size = p_color_map->get_size();
    Ref<Image> image = Image::create(canvas_size.x, canvas_size.y, false, Image::FORMAT_R8);

    bool inside = started_point.x < canvas_size.x && started_point.x >= 0 && started_point.y < canvas_size.y && started_point.y >= 0;
    if( !inside ){
        return image;
    }

    int32_t locked_color = p_color_map->get_pixel(started_point.x, started_point.y).get_r8();

    PixelPenCPP::flood_fill_iterative(locked_color, started_point, p_color_map, image, grow_only_along_axis);

    Ref<Image> mask_image = Image::create(canvas_size.x + mask_margin.x * 2, canvas_size.y + mask_margin.y * 2, false, Image::FORMAT_R8);
    mask_image->blit_rect(image, Rect2i(Vector2i(), canvas_size), mask_margin);

    return mask_image;
}


void PixelPenCPP::flood_fill_iterative(int32_t reference_color, Vector2i start_point, const Ref<Image>  &p_color_map, const Ref<Image> &p_image, const bool grow_only_along_axis = false) {
    Vector2i canvas_size = p_color_map->get_size();

    std::queue<Vector2i> points_queue;
    points_queue.push(start_point);

    while (!points_queue.empty()) {
        Vector2i current_point = points_queue.front();
        points_queue.pop();

        if (current_point.x < 0 || current_point.x >= canvas_size.x || current_point.y < 0 || current_point.y >= canvas_size.y) {
            continue; // Skip if out of bounds
        }

        int32_t current_color = p_color_map->get_pixel(current_point.x, current_point.y).get_r8();
        if (current_color == reference_color && p_image->get_pixel(current_point.x, current_point.y).get_r8() == 0) {
            Color c = Color(0, 0, 0, 0);
            c.set_r8(255);
            p_image->set_pixel(current_point.x, current_point.y, c);

            // Add neighboring points to the queue
            if (!grow_only_along_axis){
                points_queue.push(Vector2i(current_point.x - 1, current_point.y - 1));
                points_queue.push(Vector2i(current_point.x + 1, current_point.y - 1));
                points_queue.push(Vector2i(current_point.x + 1, current_point.y + 1));
                points_queue.push(Vector2i(current_point.x - 1, current_point.y + 1));
            }
            points_queue.push(Vector2i(current_point.x + 1, current_point.y));
            points_queue.push(Vector2i(current_point.x - 1, current_point.y));
            points_queue.push(Vector2i(current_point.x, current_point.y + 1));
            points_queue.push(Vector2i(current_point.x, current_point.y - 1));
        }
    }
}


Rect2i PixelPenCPP::get_mask_used_rect(const Ref<Image> &mask){
    Rect2i rect;
    int w = mask->get_width();
    int h = mask->get_height();
    rect.position = Vector2i(w, h);

    for (int x = 0; x < w; ++x) {
        for (int y = 0; y < h; ++y) {
            if (mask->get_pixel(x, y).get_r8() != 0) {
                rect.position.x = MIN(rect.position.x, x);
                break;
            }
        }
    }
    for (int y = 0; y < h; ++y) {
        for (int x = 0; x < w; ++x) {
            if (mask->get_pixel(x, y).get_r8() != 0) {
                rect.position.y = MIN(rect.position.y, y);
                break;
            }
        }
    }

    for (int x = w - 1; x >= 0; --x) {
        for (int y = h - 1; y >= 0; --y) {
            if (mask->get_pixel(x, y).get_r8() != 0) {
                Vector2i end = rect.get_end();
                end.x = MAX(rect.get_end().x, x);
                rect.set_end(end);
                break;
            }
        }
    }
    for (int y = h - 1; y >= 0; --y) {
        for (int x = w - 1; x >= 0; --x) {
            if (mask->get_pixel(x, y).get_r8() != 0) {
                Vector2i end = rect.get_end();
                end.y = MAX(rect.get_end().y, y);
                rect.set_end(end);
                break;
            }
        }
    }
    rect.size += Vector2i(1, 1);
    return rect;
}


bool PixelPenCPP::coor_inside_canvas(int x, int y, Vector2i size, const Ref<Image> &mask = nullptr){
	bool yes = x < size.x and x >= 0 and y < size.y and y >= 0;
    if(mask.is_valid()){
	    yes = yes and mask->get_pixel(x, y).get_r8() != 0;
    }
	return yes;
}


Ref<Image> PixelPenCPP::get_color_map_with_mask(const Ref<Image> &mask, const Ref<Image> &p_color_map){
    Vector2i size = p_color_map->get_size();
    Rect2i rect = mask->get_used_rect();

    
    Ref<Image> image = Image::create(size.x, size.y, false, Image::FORMAT_R8);

    for (int x = rect.position.x; x < rect.get_end().x; x++) {
        for (int y = rect.position.y; y < rect.get_end().y; y++) {
            // Check if the pixel in the mask is not transparent
            if (mask->get_pixel(x, y).get_r8() != 0) {
                image->set_pixel(x, y, p_color_map->get_pixel(x, y));
            }
        }
    }

    return image;
}


void PixelPenCPP::empty_index_on_color_map(const Ref<Image> &mask, const Ref<Image> &p_color_map){
    Rect2i rect = mask->get_used_rect();

    // Iterate over the pixels within the rectangle
    for (int x = rect.position.x; x < rect.get_end().x; x++) {
        for (int y = rect.position.y; y < rect.get_end().y; y++) {
    
            if (mask->get_pixel(x, y).get_r8() != 0) {
                p_color_map->set_pixel(x, y, Color(0,0,0,0));
            }
        }
    }
}


void PixelPenCPP::blit_color_map(const Ref<Image> &src_map, const Ref<Image> &mask, Vector2i offset, const Ref<Image> &p_color_map){
    Vector2i size = p_color_map->get_size();
    Rect2i src_rect = src_map->get_used_rect();

	Rect2i mask_rect;
    if (mask.is_valid()){
        mask_rect = mask->get_used_rect();
    }

    for (int x = 0; x < size.x; x++) {
        for (int y = 0; y < size.y; y++) {
            int _x = x - offset.x;
            int _y = y - offset.y;
            if (!PixelPenCPP::coor_inside_canvas(x, y, size) || !src_rect.has_point(Vector2i(_x, _y))) {
                continue;
            }
            bool yes = false;

            if (mask.is_null() || (mask_rect.has_point(Vector2i(_x, _y)) && mask->get_pixel(_x, _y).get_r8() != 0)) {
                Color color_index = src_map->get_pixel(_x, _y);
                if (color_index.get_r8() != 0) {
                    p_color_map->set_pixel(x, y, color_index);
                }
            }
            
        }
    }
}


void PixelPenCPP::switch_palette(const int32_t palette_index_a, const int32_t palette_index_b, const Ref<Image> &p_color_map){
	Vector2i size = p_color_map->get_size();
    for(int32_t y = 0; y < size.y; y++){
		for(int32_t x = 0; x < size.x; x++){
			if (p_color_map->get_pixel(x, y).get_r8() == palette_index_a){
                Color c = Color(0,0,0,0);
                c.set_r8(palette_index_b);
				p_color_map->set_pixel(x, y, c);
            }else if (p_color_map->get_pixel(x, y).get_r8() == palette_index_b){
                Color c = Color(0,0,0,0);
                c.set_r8(palette_index_a);
				p_color_map->set_pixel(x, y, c);
            }
        }
    }
}


void PixelPenCPP::switch_color(const int32_t palette_index_a, const int32_t palette_index_b, const Ref<Image> &p_color_map){
    Vector2i size = p_color_map->get_size();
	for(int32_t y = 0; y < size.y; y++){
		for(int32_t x = 0; x < size.x; x++){
			if (p_color_map->get_pixel(x, y).get_r8() == palette_index_a){
                Color c = Color(0,0,0,0);
                c.set_r8(palette_index_b);
				p_color_map->set_pixel(x, y, c);
            }
        }
    }
}


void PixelPenCPP::swap_palette(const PackedColorArray &old_palette, const PackedColorArray &new_palette, const Ref<Image> &p_color_map){
    Vector2i size = p_color_map->get_size();
	for(int32_t y = 0; y < size.y; y++){
		for(int32_t x = 0; x < size.x; x++){
            int32_t old_idx = p_color_map->get_pixel(x, y).get_r8();
            if(old_palette[old_idx] != new_palette[old_idx]){
                int32_t new_idx = new_palette.find(old_palette[old_idx]);
                Color c = Color(0,0,0,0);
                if(new_idx != -1){
                    c.set_r8(new_idx);
                }
                p_color_map->set_pixel(x, y, c);
                
            }
        }
    }
}


void PixelPenCPP::move_shift(const Vector2i direction, const Ref<Image> &p_image){
    Vector2i size = p_image->get_size();
    Ref<Image> crop = p_image->duplicate();
    bool r8 = p_image->get_format() == Image::FORMAT_R8;
    bool rf = p_image->get_format() == Image::FORMAT_RGBAF;
    for(int32_t y = 0; y < size.y; y++){
		for(int32_t x = 0; x < size.x; x++){
            int32_t x_shift = x + direction.x;
            int32_t y_shift = y + direction.y;
            bool outside = x_shift < 0 || x_shift >= size.x || y_shift < 0 || y_shift >= size.y;
            if(outside){
                continue;
            }
            if (r8){
                Color c = crop->get_pixel(x, y);
                if(c.get_r8() > 0){
                    p_image->set_pixel(x_shift, y_shift, c);
                }
            }else if (rf){
                Color c = crop->get_pixel(x, y);
                if(c.a > 0){
                    p_image->set_pixel(x_shift, y_shift, c);
                }
            }
        }
    }
}


void PixelPenCPP::blend(const Ref<Image> &target_image, const Ref<Image> &src_image, const Vector2i offset){
    Vector2i src_size = src_image->get_size();
    Vector2i target_size = target_image->get_size();
    bool r8 = src_image->get_format() == Image::FORMAT_R8;
    bool rf = src_image->get_format() == Image::FORMAT_RGBAF;
    for(int32_t y = 0; y < src_size.y; y++){
		for(int32_t x = 0; x < src_size.x; x++){
            int32_t x_shift = x + offset.x;
            int32_t y_shift = y + offset.y;
            bool outside = x_shift < 0 || x_shift >= target_size.x || y_shift < 0 || y_shift >= target_size.y;
            if(outside){
                continue;
            }
            if (r8){
                Color c = src_image->get_pixel(x, y);
                if(c.get_r8() > 0){
                    target_image->set_pixel(x_shift, y_shift, c);
                }
            }else if (rf){
                Color c = src_image->get_pixel(x, y);
                if(c.a > 0){
                    target_image->set_pixel(x_shift, y_shift, c);
                }
            }
        }
    }
}


PackedColorArray PixelPenCPP::import_image(const Ref<Image> &layer_image, const Ref<Image> &imported_image, const PackedColorArray palette){
    PackedColorArray returned_palette = palette;
    Vector2i layer_size = layer_image->get_size();
    Vector2i imported_size = imported_image->get_size();
    for(int32_t y = 0; y < layer_size.y; y++){
		for(int32_t x = 0; x < layer_size.x; x++){
			if (x < imported_size.x and y < imported_size.y){
                Color color = imported_image->get_pixel(x, y);
                if(color.a == 0){
                    continue;
                }
                int32_t palette_index = returned_palette.find(color);
                if (palette_index == -1){
                    palette_index = 0;
                    for(int32_t i = 1; i < returned_palette.size();  i++){
                        if(returned_palette[i].a == 0){
                            palette_index = i;
                            returned_palette[i] = color;
                            break;
                        }
                    }
                }
                if(palette_index != 0){
                    Color c = Color(0,0,0,0);
                    c.set_r8(palette_index);
                    layer_image->set_pixel(x, y, c);
                }
            }
        }
    }
    return returned_palette;
}


Ref<Image> PixelPenCPP::get_image(PackedColorArray palette_color, const Ref<Image> &p_color_map, const bool mipmap){
	Vector2i size = p_color_map->get_size();
    Ref<Image> cache_image = Image::create(size.x, size.y, mipmap, Image::FORMAT_RGBAF);

	for(int32_t y = 0; y < size.y; y++){
		for(int32_t x = 0; x < size.x; x++){
			if (p_color_map->get_pixel(x, y).get_r8() != 0){
				cache_image->set_pixel(x, y, palette_color[p_color_map->get_pixel(x, y).get_r8()]);
            }
        }
    }
	return cache_image;
}


Ref<Image> PixelPenCPP::get_image_with_mask(PackedColorArray palette_color, const Ref<Image> &p_color_map, Ref<Image> mask, const bool mipmap){
	Vector2i size = p_color_map->get_size();
    Ref<Image> cache_image = Image::create(size.x, size.y, mipmap, Image::FORMAT_RGBAF);

	int32_t i  = 0;
	for(int32_t y = 0; y < size.y; y++){
		for(int32_t x = 0; x < size.x; x++){
			if (p_color_map->get_pixel(x, y).get_r8() != 0 and mask->get_pixel(x, y).get_r8() != 0){
				cache_image->set_pixel(x, y, palette_color[p_color_map->get_pixel(x, y).get_r8()]);
            }
        }
    }
	return cache_image;
}