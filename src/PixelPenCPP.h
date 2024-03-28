#ifndef PIXELPENCPP_H
#define PIXELPENCPP_H

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/classes/image.hpp>

namespace godot{

    class PixelPenCPP : public RefCounted{
        GDCLASS(PixelPenCPP, RefCounted)

        private:
            void flood_fill_iterative(int32_t reference_color, Vector2i start_point, const Ref<Image> &p_color_map, const Ref<Image> &p_image, const bool grow_only_along_axis);
            

        protected:
            static void _bind_methods();

        public:
            PixelPenCPP();
            ~PixelPenCPP();
            String version();
            Ref<Image> get_mask_flood(Vector2i started_point, const Ref<Image> &p_color_map, Vector2i mask_margin, const bool grow_only_along_axis);
            Rect2i get_mask_used_rect(const Ref<Image> &mask);
            bool coor_inside_canvas(int x, int y, Vector2i size, const Ref<Image> &mask);
            Ref<Image> get_color_map_with_mask(const Ref<Image> &mask, const Ref<Image> &p_color_map);
            void empty_index_on_color_map(const Ref<Image> &mask, const Ref<Image> &p_color_map);
            void blit_color_map(const Ref<Image> &src_map, const Ref<Image> &mask, Vector2i offset, const Ref<Image> &p_color_map);
            void switch_palette(const int32_t palette_index_a, const int32_t palette_index_b, const Ref<Image> &p_color_map);
            void switch_color(const int32_t palette_index_a, const int32_t palette_index_b, const Ref<Image> &p_color_map);
            void swap_palette(const PackedColorArray &old_palette, const PackedColorArray &new_palette, const Ref<Image> &p_color_map);
            void move_shift(const Vector2i direction, const Ref<Image> &p_image);
            void blend(const Ref<Image> &target_image, const Ref<Image> &src_image, const Vector2i offset);
            PackedColorArray import_image(const Ref<Image> &layer_image, const Ref<Image> &imported_image, const PackedColorArray palette);
            Ref<Image> get_image(PackedColorArray palette_color, const Ref<Image> &p_color_map, const bool mipmap);
            Ref<Image> get_image_with_mask(PackedColorArray palette_color, const Ref<Image> &p_color_map, Ref<Image> mask, const bool mipmap);
    };
    
}

#endif
 