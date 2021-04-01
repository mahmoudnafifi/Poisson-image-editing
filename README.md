Matlab implementation of:
Pérez, Patrick, Michel Gangnet, and Andrew Blake. "Poisson image editing." ACM Transactions on Graphics (TOG). Vol. 22. No. 3. ACM, 2003.

![PIE](https://user-images.githubusercontent.com/37669469/113340138-802ee100-92f9-11eb-9f3d-3636cd80a528.jpg)

Gradient domain is used instead of intensity of pixels in image cloning to blend two images by solving Poisson equations with a predefined boundary condition. Based on this idea, there are two options:
1- Seamless cloning
2- Mixing gradients
For more information read Readme.pdf

### Get Started

1- Open Demo.m
2- Change the filenames accordingly; in the current demo we assume the source, target, and result images have the following filenames:
source='source_image.jpg';
target='target_image.jpg';
result='result_image.jpg';
3- Run Demo.m


### Related projects:

[MPB](https://github.com/mahmoudnafifi/modified-Poisson-image-editing): A modified Poisson blending to reduce PIE bleeding artifacts by a simple two-stage blending approach.
