<template>
  <component
    :is="componentType"
    :visualization="visualization"
    :isSelected="isSelected"
    :canHover="canHover"
    :selectMode="selectMode"
    @toggleSelection="toggleSelection"
    @contentChanged="onContentChanged" />
</template>

<script>
import CondensedMapCard from './CondensedMapCard';
import SimpleMapCard from './SimpleMapCard';
import props from './shared/props';

export default {
  name: 'MapCard',
  props: {
    ...props,
    condensed: {
      type: Boolean,
      default: false
    }
  },
  components: {
    SimpleMapCard,
    CondensedMapCard
  },
  computed: {
    componentType () {
      return this.condensed ? 'CondensedMapCard' : 'SimpleMapCard';
    }
  },
  methods: {
    toggleSelection ($event) {
      this.$emit('toggleSelection', {
        map: this.$props.visualization,
        isSelected: !this.$props.isSelected,
        event: $event
      });
    },
    onContentChanged (type) {
      this.$emit('contentChanged', type);
    }
  }
};
</script>
